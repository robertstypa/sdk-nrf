#
# Copyright (c) 2024 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

if(SB_CONFIG_SUIT_BUILD_FLASH_COMPANION)
  # Calculate the network board target
  string(REPLACE "/" ";" split_board_qualifiers "${BOARD_QUALIFIERS}")
  list(GET split_board_qualifiers 1 target_soc)
  list(GET split_board_qualifiers 2 target_cpucluster)

  set(board_target "${BOARD}/${target_soc}/${SB_CONFIG_FLASH_COMPANION_TARGET_CPUCLUSTER}")

  ExternalZephyrProject_Add(
    APPLICATION flash_companion
    SOURCE_DIR "${ZEPHYR_NRF_MODULE_DIR}/samples/suit/flash_companion"
    BOARD ${board_target}
    BOARD_REVISION ${BOARD_REVISION}
  )
endif()

if(SB_CONFIG_SUIT_BUILD_RECOVERY)
  # Calculate the network board target
  string(REPLACE "/" ";" split_board_qualifiers "${BOARD_QUALIFIERS}")
  list(GET split_board_qualifiers 1 target_soc)
  list(GET split_board_qualifiers 2 target_cpucluster)

  set(board_target "${BOARD}/${target_soc}/${target_cpucluster}")

  ExternalZephyrProject_Add(
    APPLICATION recovery
    SOURCE_DIR ${SB_CONFIG_SUIT_RECOVERY_APPLICATION_PATH}
    BOARD ${board_target}
    BOARD_REVISION ${BOARD_REVISION}
  )

  if(SB_CONFIG_SUIT_RECOVERY_APPLICATION_IMAGE_MANIFEST_APP_RECOVERY)
    set_config_bool(recovery CONFIG_SUIT_LOCAL_ENVELOPE_GENERATE n)
  endif()
endif()

if(SB_CONFIG_SUIT_BUILD_AB_UPDATE)
  set(image ${DEFAULT_IMAGE}_b)
#  ExternalNcsVariantProject_Add(APPLICATION ${DEFAULT_IMAGE} VARIANT ${image})

  string(REPLACE "/" ";" split_board_qualifiers "${BOARD_QUALIFIERS}")
  list(GET split_board_qualifiers 1 target_soc)
  list(GET split_board_qualifiers 2 target_cpucluster)

  set(board_target "${BOARD}/${target_soc}/${target_cpucluster}")

  ExternalZephyrProject_Add(
    APPLICATION "${image}"
    SOURCE_DIR "${ZEPHYR_NRF_MODULE_DIR}/samples/suit/smp_transfer"
    BOARD ${board_target}
    BOARD_REVISION ${BOARD_REVISION}
  )

  # Dodaj overlay po utworzeniu projektu
  # add_overlay_dts(${image} "${CMAKE_CURRENT_LIST_DIR}/ab_update.overlay")

  set_config_bool("${image}" CONFIG_SUIT_LOCAL_ENVELOPE_GENERATE y)
  set_config_string("${image}" CONFIG_SUIT_ENVELOPE_TEMPLATE_FILENAME "app_b_envelope.yaml.jinja2")
  sysbuild_get(target IMAGE ${DEFAULT_IMAGE} VAR CONFIG_SUIT_ENVELOPE_TARGET KCONFIG)
  set_config_string("${image}" CONFIG_SUIT_ENVELOPE_TARGET "application_b")
  set_config_bool("${image}" CONFIG_NRF_REGTOOL_GENERATE_UICR n)
  set_config_bool("${image}" CONFIG_USE_DT_CODE_PARTITION n)
  #set_config_string("${image}" CONFIG_FLASH_LOAD_OFFSET "0xc1000")
  set_property(TARGET ${image} APPEND_STRING PROPERTY CONFIG "CONFIG_FLASH_LOAD_OFFSET=0xD7000\n")
  set_property(TARGET ${image} APPEND_STRING PROPERTY CONFIG "CONFIG_N_BLINKS=10\n")
endif()
