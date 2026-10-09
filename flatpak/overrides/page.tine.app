[Context]
# Logseq graph (same one docker/logseq mounts); edit to taste
filesystems=~/notes;

[Environment]
# Text doesn't render (graphics do) with WebKitGTK's DMA-BUF renderer on this GPU;
# falls back to shared-memory buffers, still GPU-rasterized.
# (WEBKIT_SKIA_ENABLE_CPU_RENDERING=1 also works, but rasterizes on the CPU.)
WEBKIT_DISABLE_DMABUF_RENDERER=1
