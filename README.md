# esx_realparking CONVERTED TO QB BY JERICOFX
A real car parking script for FiveM



# if you think that my time deserve a coffe

buymeacoff.ee/jericofx

# IMPORTANT INFORMATION

I found a fix to the Nil values in the server console, it happend because when we are in the selection menu, the resource want an id, at that momento we dont have that, so the fix i found is going to the rs-spawn (qb-spawn) in this part https://prnt.sc/wdv3av  put the trigger event in this case is     TriggerEvent("esx_realparking:getPlayerIden") like the image.





![Parking example](https://i.imgur.com/J6SqHBK.png)

> This script maybe has some bugs or performance issues, I need some times to fix it.

## Features

- Store the car like the real life
- Parking fees for player


## Download & Installation

 
#ESX VERSION
```
git clone https://github.com/kasuganosoras/esx_realparking
```


## Installation

- Import esx_realparking.sql to your database
- Add this in your `server.cfg`

```
start esx_realparking
```

## Videos

https://youtu.be/NPBoPn4cqLI

## Legal

### License

esx_realparking - car parking script for ESX

Copyright (C) 2020 Akkariin

This program Is free software: you can redistribute it And/Or modify it under the terms Of the GNU General Public License As published by the Free Software Foundation, either version 3 Of the License, Or (at your option) any later version.

This program Is distributed In the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty Of MERCHANTABILITY Or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License For more details.

You should have received a copy Of the GNU General Public License along with this program. If Not, see http://www.gnu.org/licenses/.
