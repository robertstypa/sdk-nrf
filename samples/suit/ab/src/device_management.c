/*
 * Copyright (c) 2025 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#include <zephyr/kernel.h>
#include <suit_manifest_variables.h>
#include <device_management.h>
#include <zephyr/logging/log.h>

LOG_MODULE_DECLARE(AB, CONFIG_SUIT_LOG_LEVEL);

/* Definitions below reflect a way of usage of manifest-controlled variables
 * in this specific application.
 */
#define BOOT_STATUS_A	       1
#define BOOT_STATUS_B	       2
#define BOOT_STATUS_A_DEGRADED 3
#define BOOT_STATUS_B_DEGRADED 4
#define BOOT_STATUS_A_NO_RADIO 5
#define BOOT_STATUS_B_NO_RADIO 6
#define BOOT_STATUS_CANT_BOOT  7

#define NOT_CONFIRMED 2
#define CONFIRMED     3

#define BOOT_PREFERENCE_A 1
#define BOOT_PREFERENCE_B 2

/** @brief Radio firmware self test
 *
 * @details
 * End-device specific self test should be implemented here.
 */
static bool radio_domain_healthy(void)
{
	/* Let's emulate a delay related to IPC communication
	 */
	k_msleep(1000);
	return true;
}

/** @brief Application firmware self test
 *
 * @details
 * End-device specific self test should be implemented here. Enabling
 * CONFIG_EMULATE_APP_HEALTH_CHECK_FAILURE allows to emulate a faulty
 * firmware, unable to confirm its health, and ultimately to test
 * a rollback to previous firmware after the update.
 */
static bool app_domain_healthy(void)
{
	if (IS_ENABLED(CONFIG_EMULATE_APP_HEALTH_CHECK_FAILURE)) {
		return false;
	}

	return true;
}

void device_healthcheck(void)
{
	suit_plat_err_t err = SUIT_PLAT_SUCCESS;
	char *img_set = NULL;
	uint32_t mfst_var_boot_status = BOOT_STATUS_CANT_BOOT;
	uint32_t mfst_var_confirm_status = CONFIRMED;
	uint32_t id_var_confirm_set = CONFIG_ID_VAR_CONFIRM_SET_A;

	err = suit_mfst_var_get(CONFIG_ID_VAR_BOOT_STATUS, &mfst_var_boot_status);
	if (err != SUIT_PLAT_SUCCESS) {
		LOG_ERR("Cannot get a device boot status");
		return;
	}

	/* Confirming only in non-degraded boot states
	 */
	if (DT_SAME_NODE(DT_ALIAS(suit_active_code_partition),
			 DT_NODELABEL(cpuapp_slot_a_partition))) {
		if (mfst_var_boot_status != BOOT_STATUS_A) {
			return;
		}
		img_set = "A";
	} else {
		if (mfst_var_boot_status != BOOT_STATUS_B) {
			return;
		}

		img_set = "B";
		id_var_confirm_set = CONFIG_ID_VAR_CONFIRM_SET_B;
	}

	err = suit_mfst_var_get(id_var_confirm_set, &mfst_var_confirm_status);
	if (err != SUIT_PLAT_SUCCESS) {
		LOG_ERR("Cannot get a confirm status");
		return;
	}

	if (mfst_var_confirm_status != CONFIRMED) {
		LOG_INF("Image set %s not confirmed yet, testing...", img_set);

		bool healthy = true;

		if (!radio_domain_healthy()) {
			LOG_ERR("Radio domain is NOT healthy");
			healthy = false;
		}

		if (!app_domain_healthy()) {
			LOG_ERR("App domain is NOT healthy");
			healthy = false;
		}

		if (!healthy) {
			LOG_ERR("Reboot the device to try to boot from previous firmware");
			return;
		}

		LOG_INF("Confirming...");
		err = suit_mfst_var_set(id_var_confirm_set, CONFIRMED);
		if (err == SUIT_PLAT_SUCCESS) {
			LOG_INF("Confirmed\n");
		}
	}
}

void toggle_preferred_boot_set(void)
{
	suit_plat_err_t err = SUIT_PLAT_SUCCESS;
	uint32_t mfst_var_boot_preference = 0;

	err = suit_mfst_var_get(CONFIG_ID_VAR_BOOT_PREFERENCE, &mfst_var_boot_preference);
	if (err != SUIT_PLAT_SUCCESS) {
		LOG_ERR("Cannot get current boot preference");
		return;
	}

	if (mfst_var_boot_preference == BOOT_PREFERENCE_B) {
		LOG_INF("Changing a boot preference (b -> A)");
		mfst_var_boot_preference = BOOT_PREFERENCE_A;
	} else {
		LOG_INF("Changing a boot preference (a -> B)");
		mfst_var_boot_preference = BOOT_PREFERENCE_B;
	}

	err = suit_mfst_var_set(CONFIG_ID_VAR_BOOT_PREFERENCE, mfst_var_boot_preference);
	if (err == SUIT_PLAT_SUCCESS) {
		LOG_INF("restart the device to enforce\n");
	} else {
		LOG_ERR("Cannot set a boot preference");
	}
}

void device_boot_state_report(void)
{
	suit_plat_err_t err = SUIT_PLAT_SUCCESS;
	uint32_t mfst_var_boot_preference = 0;
	uint32_t mfst_var_boot_status = 0;
	uint32_t mfst_var_confirm_set_a = 0;
	uint32_t mfst_var_confirm_set_b = 0;

	err = suit_mfst_var_get(CONFIG_ID_VAR_BOOT_PREFERENCE, &mfst_var_boot_preference);
	if (err == SUIT_PLAT_SUCCESS) {
		if (mfst_var_boot_preference == BOOT_PREFERENCE_B) {
			printk("Boot preference: set B\n");
		} else {
			printk("Boot preference: set A\n");
		}
	}

	err = suit_mfst_var_get(CONFIG_ID_VAR_BOOT_STATUS, &mfst_var_boot_status);
	if (err == SUIT_PLAT_SUCCESS) {
		if (mfst_var_boot_status == BOOT_STATUS_A) {
			printk("Boot status: image set A active\n");
		} else if (mfst_var_boot_status == BOOT_STATUS_B) {
			printk("Boot status: image set B active\n");
		} else if (mfst_var_boot_status == BOOT_STATUS_A_DEGRADED) {
			printk("Boot status: image set A active, degraded mode\n");
		} else if (mfst_var_boot_status == BOOT_STATUS_B_DEGRADED) {
			printk("Boot status: app image B active, degraded mode\n");
		} else if (mfst_var_boot_status == BOOT_STATUS_A_NO_RADIO) {
			printk("Boot status: app image A active, no radio, degraded mode\n");
		} else if (mfst_var_boot_status == BOOT_STATUS_B_NO_RADIO) {
			printk("Boot status: app image B active, no radio, degraded mode\n");
		} else {
			printk("Boot status: unrecognized\n");
		}
	}

	err = suit_mfst_var_get(CONFIG_ID_VAR_CONFIRM_SET_A, &mfst_var_confirm_set_a);
	if (err == SUIT_PLAT_SUCCESS) {
		if (mfst_var_confirm_set_a == NOT_CONFIRMED) {
			printk("Confirm status set A: not confirmed\n");
		} else if (mfst_var_confirm_set_a == CONFIRMED) {
			printk("Confirm status set A: confirmed\n");
		} else {
			printk("Confirm status set A: just installed\n");
		}
	}

	err = suit_mfst_var_get(CONFIG_ID_VAR_CONFIRM_SET_B, &mfst_var_confirm_set_b);
	if (err == SUIT_PLAT_SUCCESS) {
		if (mfst_var_confirm_set_b == NOT_CONFIRMED) {
			printk("Confirm status set B: not confirmed\n");
		} else if (mfst_var_confirm_set_b == CONFIRMED) {
			printk("Confirm status set B: confirmed\n");
		} else {
			printk("Confirm status set B: just installed\n");
		}
	}
}
