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
  
  message(WARNING "APPLICATION_SOURCE_DIR: ${APPLICATION_SOURCE_DIR}")
  message(WARNING "APPLICATION_DIR: ${APPLICATION_DIR}")
  message(WARNING "ZEPHYR_BASE: ${ZEPHYR_BASE}")
  message(WARNING "CMAKE_CURRENT_SOURCE_DIR: ${CMAKE_CURRENT_SOURCE_DIR}")
  message(WARNING "CMAKE_SOURCE_DIR: ${CMAKE_SOURCE_DIR}")

  ExternalZephyrProject_Add(
    APPLICATION "${image}"
    SOURCE_DIR "${ZEPHYR_NRF_MODULE_DIR}/samples/suit/suit_ab_images"
    BOARD ${board_target}
    BOARD_REVISION ${BOARD_REVISION}
  )

  set_config_bool("${image}" CONFIG_SUIT_LOCAL_ENVELOPE_GENERATE y)
  # TODO: filename and target names should be handled by sysbuild/suit.cmake during the generation of suit envelopes
  # TODO2: the goal is to have only one envelope for both images!
  # Template rendered does not know about current image,
  #   so from template renderer all variables are equal and is not possible to detect 'image_b' case
  # set_config_string("${image}" CONFIG_SUIT_ENVELOPE_TEMPLATE_FILENAME "app_envelope.yaml.jinja2")
  sysbuild_get(target IMAGE ${DEFAULT_IMAGE} VAR CONFIG_SUIT_ENVELOPE_TARGET KCONFIG)
  # TODO: target name should be handled by sysbuild/suit.cmake during the generation of suit envelopes
  set_config_string("${image}" CONFIG_SUIT_ENVELOPE_TARGET "application_b")
  set_config_bool("${image}" CONFIG_NRF_REGTOOL_GENERATE_UICR n)
  # Force application to do not use DT code partition
  # set_config_bool("${image}" CONFIG_USE_DT_CODE_PARTITION n)
  # set_property(TARGET ${image} APPEND_STRING PROPERTY CONFIG "CONFIG_FLASH_LOAD_OFFSET=0xDE800\n")
  
  # TODO: remove, added only for testing
  set_property(TARGET ${image} APPEND_STRING PROPERTY CONFIG "CONFIG_N_BLINKS=10\n")
  add_overlay_dts(${image} "${ZEPHYR_NRF_MODULE_DIR}/samples/suit/suit_ab_images/sysbuild/ab_images_b.overlay")
endif()
