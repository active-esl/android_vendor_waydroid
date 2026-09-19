# Waydroid hwcomposer patches

No downstream patch is applied to `hardware/waydroid` for the Active ESL
LineageOS 23.2 source lock.

The former `0001-hwcomposer-detect-minigbm-buffer-handles.patch` is superseded by
Active ESL hwcomposer commit
`b92200ac592ed43acd9f1f1bc41c09bc407b1732`. The product manifest must pin
`hardware/waydroid` to that exact commit when it pins this vendor revision.

That hwcomposer commit uses Android 16's public `GraphicBufferMapper` API to
read buffer width, height, pixel stride, DRM FourCC, plane layout, and format
modifier before creating the Wayland linux-dmabuf buffer. This replaces the
older handle-layout heuristic in the removed patch and supports the Arm
allocator selected by the FRDM host configuration.
