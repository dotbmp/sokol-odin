// ----------------------------------------------------------------------------
//  vulkan_smoke/main.odin
//
//  Validates the SOKOL_USE_VULKAN build path end-to-end on Linux/Windows:
//
//    1. Asks sokol-app to bring up a window with the Vulkan backend.
//    2. On the first frame, prints the Vulkan environment + swapchain
//       handles that sokol-app exposes via sapp.get_environment() and
//       sapp.get_swapchain().
//    3. Loops harmlessly until the user closes the window.
//
//  Build:
//      odin run examples/vulkan_smoke -define:SOKOL_USE_VULKAN=true
//
//  Expected output (handles will differ):
//      [smoke] frame 1
//      [smoke]   Vulkan_Environment:
//      [smoke]     instance           = 0x55a3f0a01000
//      [smoke]     physical_device    = 0x55a3f0a40000
//      [smoke]     device             = 0x55a3f0b00000
//      [smoke]     queue              = 0x55a3f0b00080
//      [smoke]     queue_family_index = 0
//      [smoke]   Vulkan_Swapchain:
//      [smoke]     render_image  = 0x55a3f0c00000  view = 0x55a3f0c00100
//      [smoke]     resolve_image = (nil)           view = (nil)
//      [smoke]     depth_stencil = 0x55a3f0c00200  view = 0x55a3f0c00300
//      [smoke]     render_finished_sem = 0x55a3f0c10000
//      [smoke]     present_complete_sem = 0x55a3f0c10080
//
//  If any of instance/physical_device/device/queue come back nil, sokol-app
//  failed to set up the Vulkan path on this machine — investigate that
//  before sinking time into a Vulkan renderer.
// ----------------------------------------------------------------------------
package main

import "base:runtime"
import "core:fmt"
import sapp "../../sokol/app"
import slog "../../sokol/log"

frame_count: u64
ctx: runtime.Context

init_cb :: proc "c" () {
    context = ctx
    fmt.println("[smoke] sokol-app initialized; waiting for first frame…")
}

frame_cb :: proc "c" () {
    context = ctx
    frame_count += 1

    // Print once on frame 1, then again every ~5 seconds, so the log shows
    // movement (proves frames are running) without spamming.
    if frame_count == 1 || frame_count % 300 == 0 {
        fmt.printfln("[smoke] frame %d", frame_count)
        env := sapp.get_environment()
        fmt.println("[smoke]   Vulkan_Environment:")
        fmt.printfln("[smoke]     instance           = %v", env.vulkan.instance)
        fmt.printfln("[smoke]     physical_device    = %v", env.vulkan.physical_device)
        fmt.printfln("[smoke]     device             = %v", env.vulkan.device)
        fmt.printfln("[smoke]     queue              = %v", env.vulkan.queue)
        fmt.printfln("[smoke]     queue_family_index = %d", env.vulkan.queue_family_index)

        sc := sapp.get_swapchain()
        fmt.println("[smoke]   Vulkan_Swapchain:")
        fmt.printfln("[smoke]     %dx%d  sample_count=%d  color=%v  depth=%v",
            sc.width, sc.height, sc.sample_count, sc.color_format, sc.depth_format)
        fmt.printfln("[smoke]     render_image  = %v  view = %v", sc.vulkan.render_image,        sc.vulkan.render_view)
        fmt.printfln("[smoke]     resolve_image = %v  view = %v", sc.vulkan.resolve_image,       sc.vulkan.resolve_view)
        fmt.printfln("[smoke]     depth_stencil = %v  view = %v", sc.vulkan.depth_stencil_image, sc.vulkan.depth_stencil_view)
        fmt.printfln("[smoke]     render_finished_sem  = %v", sc.vulkan.render_finished_semaphore)
        fmt.printfln("[smoke]     present_complete_sem = %v", sc.vulkan.present_complete_semaphore)
    }
}

cleanup_cb :: proc "c" () {
    context = ctx
    fmt.println("[smoke] shutting down")
}

main :: proc() {
    ctx = context
    sapp.run({
        init_cb     = init_cb,
        frame_cb    = frame_cb,
        cleanup_cb  = cleanup_cb,
        width       = 800,
        height      = 600,
        window_title = "vulkan_smoke",
        icon        = { sokol_default = true },
        logger      = { func = slog.func },
    })
}
