# Microcontroller Pong

Have you ever heard of hit 1970's video game 'Pong'?

<br> <br> <br>

## Introduction

If for some reason you haven't, Pong is an objectively simple game to both learn and play. Think of it almost like ping pong (I wonder where Pong got its name from...) but it requires basically no skill to actually play and you've got yourself Pong!

For the uninformed, here is the basic gameplay loop of Pong:
 - Ball starts at center of the screen and goes in a random direction
 - Ball bounces off of top and bottom walls (inverting the Y speed)
 - Ball bounces off player paddle and goes the opposite direction
 - Repeat until ball reaches one end of the screen [give opposite player score and start from top]

As you can see, it is a fairly simple game (and is specifically the reason I chose it).
<br> <br> <br> <br> <br> <Must be chilly. So many brs>

## Purpose of the Project

This repository houses the spaghetti coded abomination of a code-base was made in a month or two for a class final project, which focused on using the Mini-Xplained AtMega328PB microcontroller to create something that fit the following criteria:
 - [x] It has to take an input
 - [x] It had to do some processing on that input
 - [x] It had to output something
 - [x] It had to use interrupts in a notable way

If you were to try and disect the disaster that is the 'Pong' directory, you'll see that this project does
indeed satisfy the listed criteria. In fact, this project goes above and beyond to the point where it is mostly
VHDL code running on a FPGA (Field Programmable Gate Array) board completely unrelated to the course (just to 
have some fun flashing lights on a monitor).

Eventually I plan on redesigning most if not all of this project, the C part was hastily made in 2-3 days
(and I prefer C++ as a language, don't care or need the STL for this [which AVR-GCC does not support]) and
severly needs to be redesigned as it has some bugs that I cannot really track down the cause of (updating the
score segments causes one of the player 1 inputs to go low, causing the player to move for some reason). 

The VHDL part is something im fairly proud of, though there are definitely some things I want to do with it to make it an objectively better codebase as it suffers from only using features in the original VHDL specification (VHDL-19 anyone???). Things like 'Matching Relational Operators' and even 'Block Comments' are just going to be nice to have and will hopefully make the project just easier to read overall. There are still
many ways I can go about improving my VHDL skills as I had very recently been taught the language (Summer 2024).

That is really all I can think of at the current moment, I will probably review this again at a later date.