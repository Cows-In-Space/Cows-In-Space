require 'ruby2d'

set title: 'Cows in Space'
set width: 1280
set height: 720

class Star
  def initialize
    @y_velocity = rand(-5..0)
    @shape = Circle.new(
      x: rand(Window.width),
      y: rand(Window.height),
      radius: rand(1..2),
      color: 'random',
      z: -2
    )
  end

  def move
    @shape.y = (@shape.y + @y_velocity) % Window.height
  end
end

class Player
  WIDTH = 32 * 3
  HEIGHT = 46 * 3
  ROTATE_SPEED = 5
  VELOCITY_INCREASE_SPEED = 0.2
  MAX_VELOCITY = 10
  SLOW_DOWN_RATE = 0.99

  attr_reader :image, :x, :y, :speed, :fire_rate

  def initialize(image, x, y, speed, fire_rate)
    @x_velocity = 0
    @y_velocity = 0
    @image = image
    @x = x
    @y = y
    @speed = speed
    @fire_rate = fire_rate
    @projectiles = []
    @last_projectile_fired_frame = 0
    @sprite = Sprite.new(
      image,
      clip_width: 32,
      width: WIDTH,
      height: HEIGHT,
      x: x,
      y: y,
      rotate: 180,
      animations: {
        moving_slow: 1..2,
        moving_fast: 3..4
      }
    )
  end

  def animate_slow
    @sprite.play(animation: :moving_slow, loop: true)
  end

  def animate_fast
    @sprite.play(animation: :moving_fast, loop: true)
  end

  def rotate(direction)
    case direction
    when :left
      @sprite.rotate -= ROTATE_SPEED
    when :right
      @sprite.rotate += ROTATE_SPEED
    end
  end

  def accelerate(direction)
    animate_fast

    x_component = Math.sin(@sprite.rotate * Math::PI / 180) * VELOCITY_INCREASE_SPEED * (@speed / 100.0)
    y_component = Math.cos(@sprite.rotate * Math::PI / 180) * VELOCITY_INCREASE_SPEED * (@speed / 100.0)

    case direction
    when :forwards
      @x_velocity += x_component
      @y_velocity -= y_component
    when :backwards
      @x_velocity -= x_component
      @y_velocity += y_component
    end

    total_velocity = @x_velocity.abs + @y_velocity.abs

    if total_velocity > MAX_VELOCITY
      @x_velocity = @x_velocity * (MAX_VELOCITY / total_velocity)
      @y_velocity = @y_velocity * (MAX_VELOCITY / total_velocity)
    end
  end

  def move
    @sprite.x += @x_velocity
    @sprite.y += @y_velocity

    if @sprite.x > Window.width + @sprite.width
      @sprite.x = -@sprite.width
    elsif @sprite.x < -@sprite.width
      @sprite.x = Window.width + @sprite.width
    end

    if @sprite.y > Window.height + @sprite.height
      @sprite.y = -@sprite.height
    elsif @sprite.y < -@sprite.height
      @sprite.y = Window.height + @sprite.height
    end

    @projectiles.each do |projectile|
      projectile.move
    end
  end

  def slow_down
    @x_velocity *= SLOW_DOWN_RATE
    @y_velocity *= SLOW_DOWN_RATE
  end

  def stop_accelerating
    animate_slow
  end

  def fire_projectile
    if @last_projectile_fired_frame + 25 - (@fire_rate / 10) < Window.frames
      x_component = Math.sin(@sprite.rotate * Math::PI / 180)
      y_component = -Math.cos(@sprite.rotate * Math::PI / 180)

      x = @sprite.x + (@sprite.width * 0.5) + (x_component * @sprite.width)
      y = @sprite.y + (@sprite.height * 0.5) + (y_component * @sprite.height)
      direction = 0

      @projectiles.push(Projectile.new(x, y, @sprite.rotate))
      @projectiles = @projectiles.last(20)
      @last_projectile_fired_frame = Window.frames
    end
  end
end

class PlayerSelectScreen
  def initialize
    @stars = Array.new(400).map { Star.new }

    title_text = Text.new('Cows in Space', size: 72, y: 40, font: 'C:\Users\niicf\RubymineProjects\Cows-In-Space\Game\assets\fonts\PixelifySans-Regular.ttf')
    title_text.x = (Window.width - title_text.width) / 2

    player_select_text = Text.new('Selecione seu jogador: ', size: 32, y: 130, font: 'C:\Users\niicf\RubymineProjects\Cows-In-Space\Game\assets\fonts\PixelifySans-Regular.ttf')
    player_select_text.x = (Window.width - player_select_text.width) / 2

    @players = [
      Player.new('C:\Users\niicf\RubymineProjects\Cows-In-Space\Game\assets\images\jogador 1.png', Window.width * (1/4.0) - Player::WIDTH / 2, 240, 80, 80),
      Player.new('C:\Users\niicf\RubymineProjects\Cows-In-Space\Game\assets\images\jogador 2.png', Window.width * (2/4.0) - Player::WIDTH / 2, 240, 100, 60),
      Player.new('C:\Users\niicf\RubymineProjects\Cows-In-Space\Game\assets\images\jogador 3.png', Window.width * (3/4.0) - Player::WIDTH / 2, 240, 60, 100),
    ]

    @selected_player = 1

    animate_players
    add_player_masks
    set_player_stat_text
  end

  def update
    if Window.frames % 2 == 0
      @stars.each { |star| star.move }
    end
  end

  def animate_players
    @players.each_with_index do |player, index|
      if index == @selected_player
        player.animate_fast
      else
        player.animate_slow
      end
    end
  end

  def move(direction)
    if direction == :left
      @selected_player = (@selected_player - 1) % 3
    else
      @selected_player = (@selected_player + 1) % 3
    end

    animate_players
    add_player_masks
    set_player_stat_text
  end

  def add_player_masks
    @player_masks && @player_masks.each { |mask| mask.remove }

    @player_masks = @players.each_with_index.map do |player, index|
      if index == @selected_player
        color = [0.2, 0.2, 0.2, 0.6]
        z = -1
      else
        color = [0.0, 0.0, 0.0, 0.6]
        z = 2
      end

      Circle.new(
        radius: 100,
        sectors: 32,
        x: player.x + (Player::WIDTH / 2),
        y: player.y + (Player::HEIGHT / 2),
        color: color,
        z: z
      )
    end
  end

  def set_player_stat_text
    @player_stat_texts && @player_stat_texts.each { |text| text.remove }

    @player_stat_texts = []
    @players.each_with_index do |player, index|
      if index == @selected_player
        color = Color.new([1,1,1,1])
      else
        color = Color.new([0.3,0.3,0.3,1])
      end

      speed_text = Text.new("Velocidade - #{player.speed}%", size: 20, y: player.y + 200, color: color, font: 'C:\Users\niicf\RubymineProjects\Cows-In-Space\Game\assets\fonts\PixelifySans-Regular.ttf')
      speed_text.x = player.x + ((Player::WIDTH - speed_text.width)/2)

      fire_rate_text = Text.new("Quantia de disparo - #{player.fire_rate}%", size: 20, y: player.y + 220, color: color, font: 'C:\Users\niicf\RubymineProjects\Cows-In-Space\Game\assets\fonts\PixelifySans-Regular.ttf')
      fire_rate_text.x = player.x + ((Player::WIDTH - fire_rate_text.width)/2)

      @player_stat_texts.push(speed_text)
      @player_stat_texts.push(fire_rate_text)
    end

  end

  def selected_player
    @players[@selected_player]
  end
end

class Asteroid
  WIDTH = 20 * 4
  HEIGHT = 17 * 4
  SPEEDS = (1..4).to_a
  ROTATIONS = (-2..2).to_a

  def initialize
    scale = 0.5 + (rand * 1.5)
    speed = SPEEDS.sample
    @rotation = ROTATIONS.sample
    @sprite = Sprite.new(
      'C:\Users\niicf\RubymineProjects\Cows-In-Space\Game\assets\images\Idle.png',
      x:rand(Window.width),
      y: rand(Window.height),
      width: WIDTH * scale,
      height: HEIGHT * scale,
      rotate: rand(360)
    )

    @x_velocity = Math.sin(@sprite.rotate * Math::PI / 180) * speed
    @y_velocity = -Math.cos(@sprite.rotate * Math::PI / 180) * speed
  end

  def move
    @sprite.rotate += @rotation
    @sprite.x += @x_velocity
    @sprite.y += @y_velocity

    if @sprite.x > Window.width + @sprite.width
      @sprite.x = -@sprite.width
    elsif @sprite.x < -@sprite.width
      @sprite.x = Window.width + @sprite.width
    end

    if @sprite.y > Window.height + @sprite.height
      @sprite.y = -@sprite.height
    elsif @sprite.y < -@sprite.height
      @sprite.y = Window.height + @sprite.height
    end
  end
end

class GameScreen
  MAX_ASTEROIDS = 8
  def initialize(player)
    @stars = Array.new(300).map { Star.new }
    @player = Player.new(player.image, player.x, player.y, player.speed, player.fire_rate)
    @player.animate_slow
    @asteroids = []
  end

  def update
    if Window.frames % 2 == 0
      @stars.each { |star| star.move }
    end

    if Window.frames % 120 == 0 && @asteroids.size <= MAX_ASTEROIDS
      @asteroids.push(Asteroid.new)
    end

    @asteroids.each { |asteroid| asteroid.move }

    @player.move
    @player.slow_down
  end

  def rotate_player(direction)
    @player.rotate(direction)
  end

  def accelerate_player(direction)
    @player.accelerate(direction)
  end

  def stop_accelerating_player
    @player.stop_accelerating
  end

  def player_fire_projectile
    @player.fire_projectile
  end
end

class Projectile
  WIDTH = 50 * 0.6
  HEIGHT = 42 * 0.6
  SPEED = 12
  def initialize(x, y, rotate)
    @image = Sprite.new(
      'C:\Users\niicf\RubymineProjects\Cows-In-Space\Game\assets\images\Pow Pow Tei Tei 2.0.png',
      x: x,
      y: y,
      width: WIDTH,
      height: HEIGHT,
      rotate: rotate,
    )

    @x_velocity = Math.sin(@image.rotate * Math::PI / 180) * SPEED
    @y_velocity = -Math.cos(@image.rotate * Math::PI / 180) * SPEED
  end

  def move
    @image.x += @x_velocity
    @image.y += @y_velocity
  end
end

current_screen = PlayerSelectScreen.new

update do
  current_screen.update
end

on :key_down do |event|
  case current_screen
  when PlayerSelectScreen
    case event.key
    when 'left'
      current_screen.move(:left)
    when 'right'
      current_screen.move(:right)
    when 'return'
      Window.clear
      current_screen = GameScreen.new(current_screen.selected_player)
    end
  end
end

on :key_held do |event|
  case current_screen
  when GameScreen
    case event.key
    when 'up'
      current_screen.accelerate_player(:forwards)
    when 'down'
      current_screen.accelerate_player(:backwards)
    when 'left'
      current_screen.rotate_player(:left)
    when 'right'
      current_screen.rotate_player(:right)
    when 'space'
      current_screen.player_fire_projectile
    end
  end
end

on :key_up do |event|
  case current_screen
  when GameScreen
    case event.key
    when 'up', 'down'
      current_screen.stop_accelerating_player
    end
  end
end

show