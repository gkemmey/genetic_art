require 'rubygems'
require 'RMagick'
include Magick

@OUTPUT_FILE = 'images/lisa_simpson'

@READ_FROM_FILE = false

@NUMBER_OF_POLYGONS = 625
@NUMBER_OF_ITERATIONS = 10000
@NUMBER_OF_ORIGINAL = 6  # original population size
@NUMBER_OF_MUTATIONS = 1
@NUMBER_OF_NEW = 3
@NUMBER_OF_RANDOM = 3
@NUMBER_OF_BEST = 3

@BORDER_SIZE = 0

@TARGET_IMAGE = ImageList.new("lisa_simpson.jpg")
@TARGET_IMAGE_PIXELS = @TARGET_IMAGE.get_pixels(@BORDER_SIZE, @BORDER_SIZE, 
        @TARGET_IMAGE.columns - 2 * @BORDER_SIZE, @TARGET_IMAGE.rows - 2 * @BORDER_SIZE)
        
@SHAPE = 'triangle' #triangle, line

@generation_number = 0
@population = []



# note about genomes and population:
# entire population is stored as an array of genomes
# each genome is a nested array
#     first item is an array that contains the fitness score (once it is calculated)
#     second item is an array that contains all the polygons, each of which is a nested array
#         first item is color as string of form "#FFFFFF"
#         second item is opacity as float of form 0.45
#         third through eigth items are vertices x1,y1,x2,y2,x3,y3 as integers
#    third item is an array of pixels returned from rmagick's get_pixels function (kept for optimization purposes)



#--------------------- POPULATION METHODS ---------------------



def create_polygon 
  polygon = []
  
  random_color = Pixel.new(rand(256), rand(256), rand(256), 0).to_color
  polygon.push(random_color)
  
  opacity = rand(101) / 100.0
  polygon.push(opacity)
  
  x,y = rand(290), rand(290)
  
  case @SHAPE
    when 'triangle'
      polygon << x << y << x << y + 10 << x + 10 << y + 10
    when 'line'
      polygon << x << y << x + rand(21) - 10 << y + rand(21) - 10
  end
  
  return polygon
end #create_polygon



def create_initial_population_grid
  j = 0
  while j < @NUMBER_OF_ORIGINAL
    
    image = []
    
    square_root = Math.sqrt(@NUMBER_OF_POLYGONS).floor
    length = ((300 - 2 * @BORDER_SIZE) / square_root).floor
    
    square_root.times do |m|
      square_root.times do |n|
        x = length * m + @BORDER_SIZE
        y = length * n + @BORDER_SIZE
                
        polygon = []
        case @SHAPE
          when 'triangle'
            polygon << '#777777' << 0.50 << x << y << x << y + length << x + length << y + length
          when 'line'
            polygon << '#777777' << 0.50 << x << y << x + length << y + length
        end
          
        image.push polygon
      end
    end
    
    j = j + 1
    
    pixels = get_storage_pixels image
    image.push pixels
    
    fitness = calculate_fitness image
    image.insert(0, [fitness])

    @population.push image
  end
end #create_initial_population_grid



def  create_initial_population_from_file
  File.open(@OUTPUT_FILE + '.txt', 'r') do |file| 
    @generation_number = file.gets.to_i
    
    (@NUMBER_OF_BEST + @NUMBER_OF_RANDOM).times do |i| # number of images
      image = []
      @NUMBER_OF_POLYGONS.times do |j|
        polygon = []
        polygon.push file.gets.chomp # color
        polygon.push file.gets.to_f # opacity
        case @SHAPE
          when 'triangle'
            6.times { polygon.push file.gets.to_i }
          when 'line'
            4.times { polygon.push file.gets.to_i }
        end
        image.push polygon
      end
      
      pixels = get_storage_pixels image
      image.push pixels
    
      fitness = calculate_fitness image
      image.insert(0, [fitness])

      @population.push image
      
      file.gets # ignore dashed separator
    end
  end
end



def crossover
  parent1 = @population[rand(@interim_population_size)]
  parent2 = @population[rand(@interim_population_size)]

  slice_point = rand(@NUMBER_OF_POLYGONS) + 1
  
  new_image = []
  j = 1 # this variable is NOT reset between while loops
  while j < slice_point
    new_image.push(parent1[j])
    j = j + 1
  end
  
  while j < parent1.length - 1
    new_image.push(parent2[j])
    j = j + 1
  end
  
  pixels = get_storage_pixels new_image
  new_image.push pixels
  
  fitness = calculate_fitness new_image
  new_image.insert(0, [fitness])
  
  @population.push new_image
end #crossover



def select_survivors
  population = @population.sort
  survivors = []
  
  j = 0 
  while j < @NUMBER_OF_BEST
    survivors.push population[j]
    j = j + 1
  end
  
  j = 0
  while j < @NUMBER_OF_RANDOM
    index = @NUMBER_OF_BEST + rand(population.length - @NUMBER_OF_BEST)
    survivors.push population[index]
    population.delete_at(index)
    j = j + 1
  end
  
  @population = survivors
end #select_survivors



#--------------------- MUTATIONS ---------------------



def swap_polygons old_image
  new_image = []
  old_image.each { |i| new_image.push i }
  
  polygon_to_mutate1 = rand(@NUMBER_OF_POLYGONS) + 1
  polygon_to_mutate2 = rand(@NUMBER_OF_POLYGONS) + 1

  new_image[polygon_to_mutate1], new_image[polygon_to_mutate2] = new_image[polygon_to_mutate2], new_image[polygon_to_mutate1]
  
  return calculate_lcr_fit(new_image[polygon_to_mutate1], new_image[polygon_to_mutate2], new_image)
end #swap_polygons



def replace_opacity old_image
  new_image = []
  old_image.each { |i| new_image.push i }
  
  polygon_to_mutate = rand(@NUMBER_OF_POLYGONS) + 1
  mutated_polygon = []
  # make sure we don't change polygon in old_image by purposefully copying here
  new_image[polygon_to_mutate].each { |i| mutated_polygon.push i }
   
  mutated_polygon[1] = rand(101) / 100.0
  
  new_image[polygon_to_mutate] = mutated_polygon
  
  return calculate_lcr_fit(new_image[polygon_to_mutate], old_image[polygon_to_mutate], new_image)
end #replace_opacity



def replace_color old_image
  new_image = []
  old_image.each { |i| new_image.push i }
  
  polygon_to_mutate = rand(@NUMBER_OF_POLYGONS) + 1
  mutated_polygon = []
  # make sure we don't change polygon in old_image by purposefully copying here
  new_image[polygon_to_mutate].each { |i| mutated_polygon.push i }
  
  color = Pixel.from_color(mutated_polygon[0])
   
  mutated_polygon[0] = case rand(3)
    when 0
      Pixel.new(rand(256), color.green, color.blue).to_color
    when 1
      Pixel.new(color.red, rand(256), color.blue).to_color
    when 2
      Pixel.new(color.red, color.green, rand(256)).to_color
  end
  
  new_image[polygon_to_mutate] = mutated_polygon
  
  return calculate_lcr_fit(new_image[polygon_to_mutate], old_image[polygon_to_mutate], new_image)
end #replace_color



def replace_vertex old_image
  new_image = []
  old_image.each { |i| new_image.push i }
  
  polygon_to_mutate = rand(@NUMBER_OF_POLYGONS) + 1
  mutated_polygon = []
  # make sure we don't change polygon in old_image by purposefully copying here
  new_image[polygon_to_mutate].each { |i| mutated_polygon.push i }
  
  case @SHAPE
    when 'triangle'
      # in polygon array, x vertices at index 2, 4, 6
      which_x = (rand(3) + 1) * 2
    when 'line'
      # in polygon array, x vertices at index 2, 4
      which_x = (rand(2) + 1) * 2
  end
  mutated_polygon[which_x] += rand(21) - 10
  mutated_polygon[which_x + 1] += rand(21) - 10
  
  new_image[polygon_to_mutate] = mutated_polygon
  
  return calculate_lcr_fit(new_image[polygon_to_mutate], old_image[polygon_to_mutate], new_image)
end #replace_vertex



def replace_random old_image
  new_image = []
  old_image.each { |i| new_image.push i }
   
  polygon_to_mutate = rand(@NUMBER_OF_POLYGONS) + 1
  mutated_polygon = create_polygon
    
  new_image[polygon_to_mutate] = mutated_polygon
  
 return calculate_lcr_fit(new_image[polygon_to_mutate], old_image[polygon_to_mutate], new_image)
end #mutation



#--------------------- CALCULATIONS ---------------------



def calculate_fitness image
  canvas_pixels = image.last
  fitness = 0
  j = 0
  while j < canvas_pixels.length
    fitness = fitness + (canvas_pixels[j].red - @TARGET_IMAGE_PIXELS[j].red).abs
    fitness = fitness + (canvas_pixels[j].green - @TARGET_IMAGE_PIXELS[j].green).abs
    fitness = fitness + (canvas_pixels[j].blue - @TARGET_IMAGE_PIXELS[j].blue).abs
    
    j = j + 1
  end
  return fitness
end #calculate_fitness



def calculate_lcr_fit new_polygon, old_polygon, new_image
  max_x, max_y, min_x, min_y = find_max_and_min(new_polygon, old_polygon)

  old_lcr_pixels = []
  target_lcr_pixels = []

  y = min_y
  while y <= max_y
    
    x = min_x
    while x <= max_x
      # so far, pixel array in new_image is just a copy from old_image - it's stored at the end of the image array
      old_lcr_pixels.push new_image.last[((y - @BORDER_SIZE) * (300 - 2 * @BORDER_SIZE)) + (x - @BORDER_SIZE)]
      target_lcr_pixels.push @TARGET_IMAGE_PIXELS[((y - @BORDER_SIZE) * (300 - 2 * @BORDER_SIZE)) + (x - @BORDER_SIZE)]
      x = x + 1
    end
    
    y = y + 1
  end
  
  pixels, fitness = calculate_partial_fitness_and_pixels new_image, max_x, max_y, min_x, min_y, target_lcr_pixels, old_lcr_pixels
  
  new_image[new_image.length - 1] = pixels
  new_image[0] = [fitness]
  
  return new_image
end #calculate_lcr_fit



def calculate_partial_fitness_and_pixels new_image, max_x, max_y, min_x, min_y, target_lcr_pixels, old_lcr_pixels
  to_draw = prep_for_drawing new_image
  new_image_pixels = get_storage_pixels to_draw
  
  new_lcr_pixels = []
  
  y = min_y
  while y <= max_y
    
    x = min_x
    while x <= max_x
      new_lcr_pixels.push new_image_pixels[((y - @BORDER_SIZE) * (300 - 2 * @BORDER_SIZE)) + (x - @BORDER_SIZE)]
      x = x + 1
    end
    
    y = y + 1
  end
  
  new_lcr_fitness = 0
  j = 0
  while j < new_lcr_pixels.length
    new_lcr_fitness += (new_lcr_pixels[j].red - target_lcr_pixels[j].red).abs
    new_lcr_fitness += (new_lcr_pixels[j].green - target_lcr_pixels[j].green).abs
    new_lcr_fitness += (new_lcr_pixels[j].blue - target_lcr_pixels[j].blue).abs
    
    j = j + 1
  end
  
  old_lcr_fitness = 0
  j = 0
  while j < new_lcr_pixels.length
    old_lcr_fitness += (old_lcr_pixels[j].red - target_lcr_pixels[j].red).abs
    old_lcr_fitness += (old_lcr_pixels[j].green - target_lcr_pixels[j].green).abs
    old_lcr_fitness += (old_lcr_pixels[j].blue - target_lcr_pixels[j].blue).abs
    
    j = j + 1
  end
  
  # new_image[0][0] is still the fitness score from the old_image (before mutation)
  total_fitness = new_image[0][0] - old_lcr_fitness + new_lcr_fitness
  
  return new_image_pixels, total_fitness
end #calculate_partial_fitness_and_pixels



def find_max_and_min polygon1, polygon2
  case @SHAPE
    when 'triangle'
      # in polygon, x's at 2, 4, 6 and y's at 3, 5, 7
      max_x = [polygon1[2], polygon1[4], polygon1[6], polygon2[2], polygon2[4], polygon2[6]].max
      min_x = [polygon1[2], polygon1[4], polygon1[6], polygon2[2], polygon2[4], polygon2[6]].min
      max_y = [polygon1[3], polygon1[5], polygon1[7], polygon2[3], polygon2[5], polygon2[7]].max
      min_y = [polygon1[3], polygon1[5], polygon1[7], polygon2[3], polygon2[5], polygon2[7]].min
    when 'line'
      # in polygon, x's at 2, 4 and y's at 3, 5
      max_x = [polygon1[2], polygon1[4], polygon2[2], polygon2[4]].max
      min_x = [polygon1[2], polygon1[4], polygon2[2], polygon2[4]].min
      max_y = [polygon1[3], polygon1[5], polygon2[3], polygon2[5]].max
      min_y = [polygon1[3], polygon1[5], polygon2[3], polygon2[5]].min
  end
  
  # bound to 50 pixel border
  max_x = 300 - 1 - @BORDER_SIZE if max_x > 300 - 1 - @BORDER_SIZE
  max_y = 300 - 1- @BORDER_SIZE if max_y > 300 - 1- @BORDER_SIZE
  min_x = @BORDER_SIZE if min_x < @BORDER_SIZE
  min_y = @BORDER_SIZE if min_y < @BORDER_SIZE
  
  return max_x, max_y, min_x, min_y
end #find_max_and_min



#--------------------- DRAWING METHODS ---------------------



def draw_image image
  canvas = Image.new(300, 300) {self.background_color = 'white'}
  make_lines = Draw.new 

  image.each do |i|
    make_lines.fill(i[0])
    make_lines.fill_opacity(i[1])
    case @SHAPE
      when 'triangle'
        make_lines.polygon(i[2], i[3],
                                   i[4], i[5],
                                   i[6], i[7])
      when 'line'
        make_lines.line(i[2], i[3],
                             i[4], i[5])
    end
  end
  
  make_lines.draw(canvas)
  return canvas
end #draw_image



def get_storage_pixels image
  canvas = draw_image image
  pixels = canvas.get_pixels(@BORDER_SIZE, @BORDER_SIZE, 
          canvas.columns - 2 * @BORDER_SIZE, canvas.rows - 2 * @BORDER_SIZE)
  canvas.destroy!
  return pixels
end #get_storage_pixels



def prep_for_drawing image
  to_draw = []
  # j = 1 to @NUMBER_OF_POLYGONS + 1 will skip first item (fitness) and last item (pixel array)
  j = 1
  while j <@NUMBER_OF_POLYGONS + 1
    to_draw.push image[j]
    j = j + 1
  end

  return to_draw
end #prep_for_drawing



def write_final
  #write current population
  File.open(@OUTPUT_FILE + '.txt', 'w') do |file| 
    file.write(@generation_number.to_s + "\n")
    @population.each do |i|
      
    j = 1
    while j < @NUMBER_OF_POLYGONS + 1
      i[j].each do |k|
        file.write(k.to_s + "\n")
      end
      j = j + 1
    end
    file.write("------------------------------------------\n")
    end
  end
  
  #write current best image
  canvas = draw_image(prep_for_drawing(@population.sort.first))
  canvas.write(@OUTPUT_FILE + @generation_number.to_s + '.gif')
  canvas.destroy!
end #write_final



#--------------------- GENERATION METHODS ---------------------



def one_generation
  GC.start
  # we will be adding to end of @population as we crossover and mutate, so remember portion that is our working set
  @interim_population_size = @population.length
  @NUMBER_OF_NEW.times {crossover}
  
  @interim_population_size = @population.length

  j = 0
  while j < @interim_population_size
    if @generation_number > 500
      @population.push replace_random(@population[j])
      @population.push swap_polygons(@population[j])
      
      @NUMBER_OF_MUTATIONS.times {@population.push replace_vertex(@population[j])}
      @NUMBER_OF_MUTATIONS.times {@population.push replace_color(@population[j])}
      @NUMBER_OF_MUTATIONS.times {@population.push replace_opacity(@population[j])}
    end
    
    6.times {@population.push replace_color(@population[j])} if @generation_number < 1000
    
    j = j + 1
  end
  
  select_survivors
  
  @generation_number += 1
  puts "Finished Generation Number " + @generation_number.to_s + ' - ' + Time.now.to_s
  
  if @generation_number % 5 == 0
    puts @population.sort[0][0][0]
    write_final
  end
end #one_generation



def run_algorithm
  if @READ_FROM_FILE
    create_initial_population_from_file
  else
    create_initial_population_grid
  end
  write_final
  select_survivors
  @NUMBER_OF_ITERATIONS.times {one_generation}
end #run_algorithm



#--------------------- MAIN ---------------------



run_algorithm