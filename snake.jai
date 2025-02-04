#import "Window_Creation";
#import "Basic";
#import "Math";
#import "System";
#import "String";

Simp  :: #import "Simp";
Input :: #import "Input";

#run {
    #if OS == .WINDOWS {
        WR :: #import "Windows_Resources";
        WR.disable_runtime_console();
    }
}

my_window: Window_Type;

WINDOW_SIZE :: 1000;
GRID_WIDHT  :: 20;
CELL_SIZE   :: 16;
CANVAS_SIZE :: GRID_WIDHT * CELL_SIZE;
window_width, window_height: s32 = WINDOW_SIZE;

snake_head_pos: Vector2;
move_direction: Vector2;
tick_rate: float;

main :: () {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();
        Windows.timeBeginPeriod(1);
    }

    my_window = create_window(window_width, window_height, "Snake");
    window_width, window_height = Simp.get_render_dimensions(my_window);
    Simp.set_render_target(my_window, .LEFT_HANDED);

    quit := false;
    while !quit {
        Input.update_window_events();
        for Input.events_this_frame {
            if it.type == .QUIT then quit = true;

            if it.type == {
                case .KEYBOARD;
                    if it.key_pressed && it.key_code == .ESCAPE {
                        quit = true;
                    }
            }
        }
        snake_init_pos;
        draw_one_frame();
        sleep_milliseconds(10);
        reset_temporary_storage();
    }
}

draw_one_frame :: () {
    Simp.clear_render_target(.15, .08, .08, 1);
    Simp.set_shader_for_color();
    snake_init_pos();
    Simp.swap_buffers(my_window, vsync=true);
}

snake_init_pos :: () {
    Simp.immediate_quad(
        cast(float)(snake_head_pos.x)*CELL_SIZE,
        cast(float)(snake_head_pos.y)*CELL_SIZE,
        cast(float)CELL_SIZE,
        cast(float)CELL_SIZE,
        .{.50, .50, .50, 1});
}
