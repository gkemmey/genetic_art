# Genetic Art

Genetic Art was an experiment with genetic algorithms in Ruby. Genetic Art recreates an image out of triangles using a genetic algorithm. This project was inspired by Roger Johansson's post at
http://rogeralsing.com/2008/12/07/genetic-programming-evolution-of-mona-lisa/

## Ahead of Its Time

This project, @wkemmey, who had the idea to do this project and worked closely with myself to write the code, and Roger Johansson were clearly ahead of their time: https://www.theverge.com/2018/10/25/18023266/ai-art-portrait-christies-obvious-sold

## Dependencies

Genetic Art requires the following dependencies to run:

## ImageMagik

Genetic Art uses ImageMagik for image manipulation software. Information on installing ImageMagik can be found at
http://www.imagemagick.org/script/index.php

## RMagik

RMagik is a Ruby wrapper around the ImageMagik API. To install RMagik type

    % gem install rmagik

## How To Use

1. Before running the script, you will need to change some code. On line 5 change the line

        % @OUTPUT_FILE = 'images/lisa_simpson'

  to something meaningful to your image.

2. Additionally, on line 10 change

        % @TARGET_IMAGE = ImageList.new("lisa_simpson.jpg")

  the filename in quotes to the proper target image.

3. After making those changes, simply type

        % ruby genetic_art_lcr10.rb

  to run the script.

## Results

| Start | End |
|-------|-----|
| ![image](https://github.com/gkemmey/genetic_art/blob/master/lisa_simpson.jpg) | ![image](https://github.com/gkemmey/genetic_art/blob/master/images/lisa_simpson10000.gif)
