# 2Lt Sergio Rios Powershell Game Project Quackaga

# Global Counters
$global:score = 0
[int]$global:aliens_left_to_spawn = 0
$global:aliens_left_to_kill = 0
$global:num_shots = 0
$global:total_kills = 0

# Global Bool
$global:game_over = $false

# Global Constants
$global:alien = 1
$global:shot = 2
$global:empty_space = 0
$global:ship = 3
$global:hit = 4
$global:alien_pixel = @(@(" "," ","|"," "," "), @(" "," ","0"," "," "), @("{","0","|","0","}"), @(" "," ","V"," "," "), @(" "," "," "," "," "))
$global:shot_pixel = @(@(" "," "," "," "," "), @(" "," ","|"," "," "), @(" ","/","|","\"," "), @(" "," ","|"," "," "), @(" "," "," "," "," "))
$global:empty_space_pixel = @(@(" "," "," "," "," "), @(" "," "," "," "," "), @(" "," "," "," "," "), @(" "," "," "," "," "), @(" "," "," "," "," "))
$global:ship_pixel = @(@(" "," ","^"," "," "), @(" ","/","0","\"," "), @("/","=","0","=","\"), @("|","\","V","/","|"), @(" "," ","|"," "," "))
$global:hit_pixel = @(@(" "," "," "," "," "), @(" ","\","|","/"," "), @("-","-","+","-","-"), @(" ","/","|","\"," "), @(" "," "," "," "," "))
$global:logo = Get-Content .\banner.txt
$global:game_frame_height = 6
$global:frame_width = 5 # We want this to be odd so that the ship starts centered
$global:scale = 5


function Start-Game{

    # First we need to create the 2d Array of the size that we want
    # Then populate it with all of the default empty values
    $game_frame = New-GameFrame $game_frame_height $frame_width
    $ship_frame = New-ShipFrame $frame_width

    # Grab the Logo
    Show-Logo
    Write-Host "ARE YOU READY FOR QUACKAGA!!!!!"
    $pause = Read-Host "Press Enter to continue...."

    Clear-Host

    # Ask the user how many aliens to kill
    Set-Difficulty

    # Start the game loop
    Start-Loop $game_frame $ship_frame
    Write-Score
}

function Show-Logo{
    foreach ($row in $global:logo) {
        Write-Host $row
    }
}

function New-GameFrame([int]$height, [int]$width) {
    $game_frame = @()
    for ($row = 0; $row -lt $height; $row++) {
        $game_frame += ,(New-Object int[] $width)
    }
    return $game_frame
}

function New-ShipFrame([int]$width){
    $ship_frame = New-Object int[] $width
    $middle = [Math]::Floor($width/2)
    $ship_frame[$middle] = 3 
    return $ship_frame
}
function New-TranslationFrame ([int]$height, [int]$width, [int]$scale) {
    $translation_frame = @()
    for ($row = 0; $row -lt $height*$scale; $row++){
        $translation_frame += ,(New-Object string[] ($width*$scale))
    }
    return $translation_frame
}

function Set-Difficulty{
    Clear-Host
    Show-Logo
    do{
        $prompt = "Please enter the your difficult(1-9)... "
        [int]$global:aliens_left_to_spawn =  Read-Host $prompt
        if ($global:aliens_left_to_spawn -lt 1 -or $global:aliens_left_to_spawn -gt 9){
            Write-Host "Invalid Input"
        }
    }until($global:aliens_left_to_spawn -ge 1 -and $global:aliens_left_to_spawn -le 9)
    $global:aliens_left_to_kill = $global:aliens_left_to_spawn
}

function Start-Loop([array]$game_frame, [array]$ship_frame){
    do {

        # Update the game frame
        $game_frame = Update-Game $game_frame

        # Update the ship frame
        $return_obj = Update-Ship $game_frame $ship_frame

        $game_frame = $return_obj[0]
        $ship_frame = $return_obj[1]

        $test = Read-Host "Proceed to next Frame?"
        Write-Host $test

    } until ($global:game_over)
}

function Update-Game([array]$game_frame){
    #  Loop for updating Aliens and Clearing hits Bottom up Order

    # Write-Host "Frame before Update"
    # Show-GameFrame $game_frame
    
    :OUTER for ($row = $global:game_frame_height -1; $row -ge 0; $row--) {
        Write-Host "In row  $row"
        for ($column = 0; $column -lt $frame_width; $column++) {
            $pixel_value = $game_frame[$row][$column] 
            if( $pixel_value -eq $global:alien){
                $game_frame = Update-Alien $game_frame $row $column
            }elseif ($pixel_value -eq $global:hit){
                $game_frame = Clear-Hit $game_frame $row $column
            }
        }   
    }

    

    # Seperate Loop for updating Shots in Top down Order
    for ($row = 0; $row -lt $global:game_frame_height; $row++) {
        for ($column = 0; $column -lt $global:frame_width; $column++) {
            $pixel_value = $game_frame[$row][$column]
            if($pixel_value -eq $global:shot){
                Write-Host "Shot Found"
                $game_frame = Update-Shot $game_frame $row $column
            }
        }
    }

    # Write-Host "Frame post shot move"
    # Show-GameFrame $game_frame

    # After moving or clearing everything we need to add a new Alien
    if($global:aliens_left_to_spawn -gt 0){
        $game_frame = Add-Alien $game_frame 
        $global:aliens_left_to_spawn--
    }

    # Write-Host "Frame After Update"
    # Show-GameFrame $game_frame 

    # Write the Frame to the Screen
    return $game_frame
}


function Update-Alien([array]$game_frame, [int]$row, [int]$column){
    if($row -eq $global:game_frame_height-2){
        $global:game_over = $true
        $game_frame = Move-Alien $game_frame $row $column
    } elseif ($game_frame[$row+1][$column] -eq $global:shot){
        $game_frame = Update-Hit $game_frame $row $column
    } else {
        $game_frame = Move-Alien $game_frame $row $column
    }
    return $game_frame
}

function Move-Alien([array]$game_frame, [int]$row, [int]$column) {
    $game_frame[$row + 1][$column] = $global:alien
    $game_frame[$row][$column] = $global:empty_space
    return $game_frame
}

function Add-Alien([array]$game_frame) {
    $column = @(0..($global:frame_width - 1)) | Get-Random -Count 1
    $game_frame[0][$column] = $global:alien
    return $game_frame
}

function Update-Shot([array]$game_frame, [int]$row, [int]$column) {
    # Check if the shot is in the first row
    if($row -eq 0){
        $game_frame[$row][$column] = $global:empty_space
    } elseif($game_frame[$row-1][$column] -eq $global:alien) {
        $game_frame = Update-Hit $game_frame $row $column
    } else {
        $game_frame = Move-Shot $game_frame $row $column
    }
    return $game_frame
}

function Move-Shot([array]$game_frame, [int]$row, [int]$column) {
    $game_frame[$row-1][$column] = $global:shot
    $game_frame[$row][$column] = $global:empty_space
    return $game_frame
}

function Add-Shot([array]$game_frame, [int]$column){
    $game_frame[$global:game_frame_height-1][$column] = $global:shot
    return $game_frame
}

function Update-Hit([array]$game_frame, [int]$row, [int]$column) {
    $global:aliens_left_to_kill--
    $global:score++
    if( $global:aliens_left_to_kill -eq 0){
        $global:game_over = $true
    }
    $game_frame = Add-Hit $game_frame $row $column
    return $game_frame
}

function Add-Hit([array]$game_frame, [int]$row, [int]$column) {
    $game_frame[$row][$column] = $global:hit
    return $game_frame
}

function Clear-Hit([array]$game_frame, [int]$row, [int]$column) {
    $game_frame[$row][$column] = $global:empty_space
    return $game_frame
}

function Update-Ship([array]$game_frame, [array]$ship_frame) {

    # Write-Host "Frame before Update"
    # Show-ShipFrame $ship_frame 

    $shot_fired = $false
    $left_key = [ConsoleKey]::LeftArrow
    $right_key = [ConsoleKey]::RightArrow
    $spacebar = [ConsoleKey]::Spacebar

    do {
        Clear-Host
        Write-GameTranslationFrame $game_frame $ship_frame
        $key_pressed = [console]::ReadKey($false)

        # Need to determine current location of ship first
        $ship_location = [array]::IndexOf($ship_frame, $global:ship)
        switch ($key_pressed.Key) {
            $left_key {
                $ship_frame = Move-Ship $ship_frame $ship_location "left"
                break
            }
            $right_key {
                $ship_frame = Move-Ship $ship_frame $ship_location "right"
                break
            }
            $spacebar {
                $game_frame = Add-Shot $game_frame $ship_location
                $shot_fired = $true
                break
            }
        }
        # Write-Host "Frame post Update"
        # Show-ShipFrame $ship_frame

        Clear-Host
        Write-GameTranslationFrame $game_frame $ship_frame

    } until ($shot_fired)


    # Write-Host "Frame After Shot"
    # Show-ShipFrame $ship_frame 

    return @($game_frame, $ship_frame)
}

function Move-Ship([array]$ship_frame, [int]$ship_location, [string]$direction){
    Write-Host "Moving $direction"
    switch ($direction) {
        "left" { 
            if($ship_location -gt 0){
                $ship_frame[$ship_location] = $global:empty_space
                $ship_frame[$ship_location-1] = $global:ship
            }
            break
         }
        "right" { 
            if ($ship_location -lt $global:frame_width- 1) {
                $ship_frame[$ship_location] = $global:empty_space
                $ship_frame[$ship_location + 1] = $global:ship
            }
            break
         }
    }
    return $ship_frame
}


function Show-GameFrame([array]$game_frame){
    for ($row = 0; $row -lt $global:game_frame_height; $row++) {
        Write-Host $game_frame[$row]
    }
}

function Show-ShipFrame([array]$ship_frame){
    Write-Host $ship_frame
}
#Check if Write-Pixel is needed or if update frame would replace
function Write-GameTranslationFrame([array]$game_frame, [array]$ship_frame){
    
    # First create the translation frame
    $game_translation_frame = New-TranslationFrame $global:game_frame_height $global:frame_width $global:scale
    
    # Depending on the value place the right pixel to the Game Translation Frame
    for ($row = 0; $row -lt $global:game_frame_height; $row++) {
        for ($column = 0; $column -lt $global:frame_width; $column++) {
            $current_pixel = $game_frame[$row][$column]
            switch ($current_pixel) {
                $global:empty_space {
                    # Passing the generated translation 2D array, with the pixel to be placed, and the index in which this pixel should start
                    $game_translation_frame = Update-TranslationFrame $game_translation_frame $global:empty_space_pixel $row $column 
                    break
                }
                $global:alien {
                    $game_translation_frame = Update-TranslationFrame $game_translation_frame $global:alien_pixel $row $column
                    break
                }
                $global:shot {
                    $game_translation_frame = Update-TranslationFrame $game_translation_frame $global:shot_pixel $row $column
                    break
                }
                $global:hit {
                    $game_translation_frame = Update-TranslationFrame $game_translation_frame $global:hit_pixel $row $column
                    break
                }
            }
        }
    }
    # Display the Game Frame
    Show-TranslationFrame $game_translation_frame

    # We now need display the ship
    Write-ShipTranslationFrame([array]$ship_frame)

}

function Write-ShipTranslationFrame([array]$ship_frame){
    $ship_translation_frame = New-TranslationFrame 1 $global:frame_width $global:scale

    for($column = 0; $column -lt $global:frame_width; $column++){
        $current_pixel = $ship_frame[$column]
        switch ($current_pixel) {
                $global:empty_space {
                    # Passing the generated translation 2D array, with the pixel to be placed, and the index in which this pixel should start
                    $ship_translation_frame = Update-TranslationFrame $ship_translation_frame $global:empty_space_pixel 0 $column 
                    break
                }
                $global:ship {
                    $ship_translation_frame = Update-TranslationFrame $ship_translation_frame $global:ship_pixel 0 $column
                    break
                }
        }
    }

    Show-TranslationFrame $ship_translation_frame
}

function Update-TranslationFrame ([array]$translation_frame, [array]$pixel, [int]$bframe_row, [int]$bframe_column){
    $row_offset = $bframe_row * $global:scale
    $column_offset = $bframe_column * $global:scale
    for ($row = 0; $row -lt $global:scale; $row++) {
        for ($column = 0; $column -lt $global:scale; $column++) {
            $translation_frame[$row_offset+$row][$column_offset+$column] = $pixel[$row][$column]
        }
    }
    return $translation_frame
}
function Show-TranslationFrame ([array]$translation_frame) {
    Write-Host "|||" -NoNewline
    $top_border = " *" * ($global:frame_width * $global:scale)
    Write-Host $top_border -NoNewline 
    Write-Host " |||"
    foreach ($row in $translation_frame) {
        Write-Host "||| " -NoNewline
        Write-Host $row -Separator " " -NoNewline
        Write-Host " |||"
    }
    Write-Host "|||" -NoNewline
    $bottom_border = " _" * ($global:frame_width * $global:scale)
    Write-Host $top_border -NoNewline 
    Write-Host " |||"
}

function Write-Score{
    # return $game_frame
}

Start-Game