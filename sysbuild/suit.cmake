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
  
  set(SAMPLE_SOURCE_DIR ${APP_DIR})

  set(APP_IMAGE ${DEFAULT_IMAGE}_slot_b)

  string(REPLACE "/" ";" split_board_qualifiers "${BOARD_QUALIFIERS}")
  list(GET split_board_qualifiers 1 target_soc)
  list(GET split_board_qualifiers 2 target_cpucluster)

  set(BOARD_TARGET "${BOARD}/${target_soc}/${target_cpucluster}")
  

  ExternalZephyrProject_Add(
    APPLICATION ${APP_IMAGE}
    SOURCE_DIR ${SAMPLE_SOURCE_DIR}
    BOARD ${BOARD_TARGET}
    BOARD_REVISION ${BOARD_REVISION}
  )

  set_config_string(${APP_IMAGE} CONFIG_SUIT_ENVELOPE_TARGET "application_b")
  set_config_bool(${APP_IMAGE} CONFIG_NRF_REGTOOL_GENERATE_UICR n)
  
  # Choose slot_b_partition as the active code partition
  add_overlay_dts(${APP_IMAGE} "${SAMPLE_SOURCE_DIR}/sysbuild/ab_images_b.overlay")

  if(NOT (SB_CONFIG_NETCORE_NONE OR SB_CONFIG_NETCORE_EMPTY) )
    set(NET_IMAGE ${SB_CONFIG_NETCORE_IMAGE_NAME}_slot_b)
    set(NET_BOARD_TARGET "${BOARD}/${target_soc}/${SB_CONFIG_NETCORE_REMOTE_BOARD_TARGET_CPUCLUSTER}")
    set(NET_SAMPLE_SOURCE_DIR ${SB_CONFIG_NETCORE_IMAGE_PATH})

    ExternalZephyrProject_Add(
      APPLICATION ${NET_IMAGE}
      SOURCE_DIR ${NET_SAMPLE_SOURCE_DIR}
      BOARD ${NET_BOARD_TARGET}
      BOARD_REVISION ${BOARD_REVISION}
    )    

    set_config_string(${NET_IMAGE} CONFIG_SUIT_ENVELOPE_TARGET "radio_b")
    set_config_bool(${NET_IMAGE} CONFIG_NRF_REGTOOL_GENERATE_UICR n)

    # Choose slot_b_partition as the active code partition and add required overlays
    add_overlay_dts(${NET_IMAGE} "${SAMPLE_SOURCE_DIR}/sysbuild/hci_ipc.overlay")   
    add_overlay_dts(${NET_IMAGE} "${SAMPLE_SOURCE_DIR}/sysbuild/ab_images_b_net.overlay")     
  endif()
  
endif()
