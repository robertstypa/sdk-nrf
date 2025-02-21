/*
 * Copyright (c) 2025 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#include <suit_manifests_state.h>
#include <suit_components_state.h>
#include <device_management.h>

#include "common.h"
#include <zephyr/kernel.h>
#include <dk_buttons_and_leds.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(AB, CONFIG_SUIT_LOG_LEVEL);

static void button_handler(uint32_t button_state, uint32_t has_changed)
{
	if ((has_changed & DK_BTN4_MSK) && (button_state & DK_BTN4_MSK)) {
		toggle_preferred_boot_set();
	}
}

int main(void)
{
	char *app_img_name = NULL;
	int ret = 0;

	ret = dk_leds_init();
	if (ret) {
		LOG_ERR("Cannot init LEDs (err: %d)\r\n", ret);
	}

	ret = dk_buttons_init(button_handler);
	if (ret) {
		LOG_ERR("Cannot init buttons (err: %d)", ret);
	}

	dk_set_led_on(DK_LED1);
	dk_set_led_on(DK_LED2);

	if (IS_ENABLED(CONFIG_MCUMGR_TRANSPORT_BT)) {
		start_smp_bluetooth_adverts();
		k_msleep(250);
	}
	printk("\n");

	suit_mainfests_state_report();
	printk("\n");

	int blinking_led = DK_LED1;
	if (DT_SAME_NODE(DT_ALIAS(suit_active_code_partition),
			 DT_NODELABEL(cpuapp_slot_a_partition))) {
		app_img_name = "A";
	} else {
		app_img_name = "B";
		blinking_led = DK_LED2;
	}

	printk("---------------------------------------------------\n");
	printk("A/B Hello world from %s, blinks: %d, img: %s\n", CONFIG_BOARD, CONFIG_N_BLINKS,
	       app_img_name);
	printk("BUILD: %s %s\n", __DATE__, __TIME__);
	printk("---------------------------------------------------\n\n");

	suit_components_state_report();
	printk("\n");

	device_boot_state_report();
	printk("\n");

	device_healthcheck();

	while (1) {
		for (int i = 0; i < CONFIG_N_BLINKS; i++) {
			dk_set_led_off(blinking_led);
			k_msleep(250);
			dk_set_led_on(blinking_led);
			k_msleep(250);
		}

		k_msleep(5000);
	}

	return 0;
}
