#import "Window_Creation";
#import "Basic";
#import "Math";
#import "System";
#import "String";
#import "Random";

Simp  :: #import "Simp";
Input :: #import "Input";

#run {
    #if OS == .WINDOWS {
        WR :: #import "Windows_Resources";
        WR.disable_runtime_console();
    }
}

my_window: Window_Type;
my_font: *Simp.Dynamic_Font;
working_directory_set := false;

WINDOW_SIZE      :: 1000;
GRID_WIDTH       :: 20;
CELL_SIZE        :: 32;
MAX_SNAKE_LENGHT :: GRID_WIDTH * GRID_WIDTH;
CANVAS_SIZE      :: GRID_WIDTH * CELL_SIZE;
window_width, window_height: s32;

snake: [MAX_SNAKE_LENGHT]Vector2;
snake_lenght: int;
snake_head_pos: Vector2;
food_pos: Vector2;
food_state: bool;
move_direction: Vector2;
game_over: bool;
pause: bool;
tick_rate: float64  = 0.15;
tick_timer: float64 = 0.15;
data_folder: string;
Texture :: Simp.Texture;

head_map    : Texture;
body_map    : Texture;
tail_map    : Texture;
food_map    : Texture;

main :: () {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();
        Windows.timeBeginPeriod(1);
    }

    my_window = create_window(CANVAS_SIZE, CANVAS_SIZE, "Snake");
    window_width, window_height = Simp.get_render_dimensions(my_window);
    Simp.set_render_target(my_window, .LEFT_HANDED);

    data_folder = join(path_strip_filename(get_path_of_running_executable()), "textures");
    print("data_folder is '%'\n", data_folder);

    init_textures();
    my_init_fonts();
    get_new_food_pos();
    init_game();

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
                    if it.key_pressed && it.key_code == .ARROW_UP && move_direction != .{0, 1} {
                        move_direction = .{0, -1};
                    }
                    if it.key_pressed && it.key_code == .ARROW_DOWN && move_direction != .{0, -1} {
                        move_direction = .{0, 1};
                    }
                    if it.key_pressed && it.key_code == .ARROW_LEFT && move_direction != .{1, 0} {
                        move_direction = .{-1, 0};
                    }
                    if it.key_pressed && it.key_code == .ARROW_RIGHT && move_direction != .{-1, 0} {
                        move_direction = .{1, 0};
                    }
                    if it.key_pressed && it.key_code == .ENTER && game_over {
                        init_game();
                    }
                    if it.key_pressed && it.key_code == .F1 {
                        pause = !pause;
                    }
            }
        }

        if !pause {
            draw_one_frame();
        }
        sleep_milliseconds(100);
        reset_temporary_storage();
    }
}

draw_one_frame :: () {
    Simp.clear_render_target(.15, .08, .08, 1);
    Simp.set_shader_for_color();
    time := seconds_since_init();

    {
        if !game_over {
            tick_timer -= time;
            if tick_timer < 0 {
                next_part_pos := snake[0];
                snake[0] = snake[0] + move_direction;
                head_pos := snake[0];

                for 1..snake_lenght-1 {
                    if snake[it] == head_pos then game_over = true;
                }

                if head_pos.x < 0 ||
                    head_pos.y < 0 ||
                    head_pos.x >= GRID_WIDTH ||
                    head_pos.y >= GRID_WIDTH
                    then game_over = true;

                for 1..snake_lenght {
                    cur_pos := snake[it];
                    snake[it] = next_part_pos;
                    next_part_pos = cur_pos;
                }

                if head_pos == food_pos {
                    snake_lenght += 1;
                    snake[snake_lenght] = next_part_pos;
                    get_new_food_pos();
                }

                tick_timer = tick_rate + tick_timer;
                draw_snake(*head_map, *body_map, *tail_map, move_direction);
                draw_food(*food_map);
            }
        } else game_over_text();
    }
    Simp.swap_buffers(my_window, vsync=true);
}

draw_snake :: (head: *Texture, body: *Texture, tail: *Texture, move_direction: Vector2) {
    radians := (PI / 180.0);
    for 0..snake_lenght {
        center := Vector2.{
            snake[it].x * CELL_SIZE + CELL_SIZE / 2,
            snake[it].y * CELL_SIZE + CELL_SIZE / 2
        };

        dir := ifx it == 0 then move_direction else snake[it-1] - snake[it];
        rot := atan2(cast(float32)dir.y, cast(float32)dir.x);

        p0 := Vector2.{-CELL_SIZE / 2, -CELL_SIZE / 2};
        p1 := Vector2.{CELL_SIZE / 2, -CELL_SIZE / 2};
        p2 := Vector2.{CELL_SIZE / 2, CELL_SIZE / 2};
        p3 := Vector2.{-CELL_SIZE / 2, CELL_SIZE / 2};

        rp0 := rotate(p0, rot) + center;
        rp1 := rotate(p1, rot) + center;
        rp2 := rotate(p2, rot) + center;
        rp3 := rotate(p3, rot) + center;

        uv0 := Vector2.{0, 0};
        uv1 := Vector2.{1, 0};
        uv2 := Vector2.{1, 1};
        uv3 := Vector2.{0, 1};

        if rot == 90 * radians {
            uv0, uv1, uv2, uv3 = uv1, uv2, uv3, uv0;
        } else if rot == 180 * radians {
            uv0, uv1, uv2, uv3 = uv2, uv3, uv0, uv1;
        } else if rot == 270 * radians {
            uv0, uv1, uv2, uv3 = uv3, uv0, uv1, uv2;
        }

        if it == 0 {
            Simp.set_shader_for_images(head);
        } else if it == snake_lenght {
            Simp.set_shader_for_images(tail);
        } else {
            Simp.set_shader_for_images(body);
        }
        Simp.immediate_quad(rp0, rp1, rp2, rp3, .{.50, .50, .50, 1});
    }
}

draw_food :: (texture: *Texture) {
    Simp.set_shader_for_images(texture);
    Simp.immediate_quad(
        .{food_pos.x*CELL_SIZE, food_pos.y*CELL_SIZE},
        .{food_pos.x*CELL_SIZE + CELL_SIZE, food_pos.y*CELL_SIZE},
        .{food_pos.x*CELL_SIZE + CELL_SIZE, food_pos.y*CELL_SIZE + CELL_SIZE},
        .{food_pos.x*CELL_SIZE, food_pos.y*CELL_SIZE + CELL_SIZE},
        .{.1, .90, .90, 1},
    );
}

get_new_food_pos :: () {
    food_pos = .{cast(float)(cast(u32)(random_get_within_range(0.0, cast(float)GRID_WIDTH-1))),
                cast(float)(cast(u32)(random_get_within_range(0.0, cast(float)GRID_WIDTH-1)))};
}

game_over_text :: () {
    text_place := window_width/4;
    text_place_lower := window_width/2;

    Simp.draw_text(my_font, text_place, text_place, "Game Over!");
    Simp.draw_text(my_font, text_place, text_place_lower, "Press [ENTER] to star again!");
}

my_init_fonts :: () {
    if !working_directory_set {
        path := path_strip_filename(get_path_of_running_executable());
        set_working_directory(path);
        working_directory_set = true;
    }
    pixel_height := window_height / 24;
    my_font = Simp.get_font_at_size("font", "font.ttf", pixel_height);
    assert(my_font != null);
}

init_game :: () {
    snake_head_pos = .{GRID_WIDTH/3, GRID_WIDTH/3};
    snake[0] = snake_head_pos;
    snake[1] = snake_head_pos - .{0, 1};
    snake[2] = snake_head_pos - .{0, 2};
    snake_lenght = 3;
    move_direction = .{0, 1};
    pause = false;
    game_over = false;
    food_state = false;
}

init_textures :: () {
    // Snake texture
    head_map = make_texture("head.png");
    body_map = make_texture("body.png");
    tail_map = make_texture("tail.png");
    // Food for snake
    food_map = make_texture("food.png");
}

make_texture :: (name: string) -> Texture, bool {
    filename := tprint("%/%", data_folder, name);

    result: Texture;
    success := Simp.texture_load_from_file(*result, filename);

    return result, success;
}
