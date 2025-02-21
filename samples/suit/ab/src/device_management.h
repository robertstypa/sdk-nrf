/*
 * Copyright (c) 2025 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#ifndef DEVICE_MANAGEMANT_H__
#define DEVICE_MANAGEMANT_H__

#ifdef __cplusplus
extern "C" {
#endif

/** @brief Performs a self-tests and confirms
 * successful firmware update, if needed
 */
void device_healthcheck(void);

/** @brief Toggles preferred boot set
 */
void toggle_preferred_boot_set();

/** @brief Displays information about state of image sets,
 * boot preference and a boot status
 */
void device_boot_state_report(void);

#endif /* DEVICE_MANAGEMANT_H__ */
