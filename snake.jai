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

WINDOW_SIZE      :: 1000;
GRID_WIDTH       :: 20;
CELL_SIZE        :: 16;
MAX_SNAKE_LENGHT :: GRID_WIDTH * GRID_WIDTH;
CANVAS_SIZE      :: GRID_WIDTH * CELL_SIZE;
window_width, window_height: s32 = WINDOW_SIZE;

snake: [MAX_SNAKE_LENGHT]Vector2;
snake_lenght: int;
snake_head_pos: Vector2;
move_direction: Vector2;
tick_rate: float64  = 0.15;
tick_timer: float64 = 0.15;

main :: () {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();
        Windows.timeBeginPeriod(1);
    }

    my_window = create_window(window_width, window_height, "Snake");
    window_width, window_height = Simp.get_render_dimensions(my_window);
    Simp.set_render_target(my_window, .LEFT_HANDED);

    snake_head_pos = .{GRID_WIDTH/2, GRID_WIDTH/2};
    snake[0] = snake_head_pos;
    snake[1] = snake_head_pos - .{0, 1};
    snake[2] = snake_head_pos - .{0, 2};
    snake_lenght = 3;
    move_direction = .{0, 1};

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
                    if it.key_pressed && it.key_code == .ARROW_UP {
                        move_direction = .{0, -1};
                    }
                    if it.key_pressed && it.key_code == .ARROW_DOWN {
                        move_direction = .{0, 1};
                    }
                    if it.key_pressed && it.key_code == .ARROW_LEFT {
                        move_direction = .{-1, 0};
                    }
                    if it.key_pressed && it.key_code == .ARROW_RIGHT {
                        move_direction = .{1, 0};
                    }
            }
        }

        draw_one_frame(move_direction);
        sleep_milliseconds(50);
        reset_temporary_storage();
    }
}

draw_one_frame :: (move_direction: Vector2) {
    Simp.clear_render_target(.15, .08, .08, 1);
    Simp.set_shader_for_color();
    time := seconds_since_init();
    {
        tick_timer -= time;
        if tick_timer < 0 {
            next_part_pos := snake[0];
            snake[0] = snake[0] + move_direction;

            for 1..snake_lenght {
                cur_pos := snake[it];
                snake[it] = next_part_pos;
                next_part_pos = cur_pos;
            }
            draw_snake();
            tick_timer = tick_rate + tick_timer;
        }
    }
    Simp.swap_buffers(my_window, vsync=true);
}

draw_snake :: () {
    for 0..snake_lenght-1 {
        Simp.immediate_quad(
            .{snake[it].x*CELL_SIZE, snake[it].y*CELL_SIZE},
            .{snake[it].x*CELL_SIZE + CELL_SIZE, snake[it].y*CELL_SIZE},
            .{snake[it].x*CELL_SIZE + CELL_SIZE, snake[it].y*CELL_SIZE + CELL_SIZE},
            .{snake[it].x*CELL_SIZE, snake[it].y*CELL_SIZE + CELL_SIZE},
            .{.50, .50, .50, 1},
        );
    }
}
