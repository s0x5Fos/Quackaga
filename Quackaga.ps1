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
$global:alien_string = "A"
$global:shot_string = "|"
$global:empty_space_string = " "
$global:ship_string = "^"
$global:game_frame_height = 30
$global:frame_width = 11 # We want this to be odd so that the ship starts centered


function Start-Game{

    # First we need to create the 2d Array of the size that we want
    # Then populate it with all of the default empty values
    $game_frame = New-GameFrame $game_frame_height $frame_width
    $ship_frame = New-ShipFrame $frame_width

    # Ask the user how many aliens to kill
    Set-Difficulty

    # Start the game loop
    Start-Loop $game_frame $ship_frame
    Write-Score
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

function Set-Difficulty{
    Clear-Host
    do{
        $prompt = "Please enter the number of Aliens you woudl like to kill(1-9)"
        [int]$global:aliens_left_to_spawn =  Read-Host $prompt
        if ($global:aliens_left_to_spawn -lt 1 -or $global:aliens_left_to_spawn -gt 9){
            Write-Host "Invalid Input"
        }
    }until($global:aliens_left_to_spawn -ge 1 -and $global:aliens_left_to_spawn -le 9)
    $global:aliens_left_to_kill = $global:aliens_left_to_spawn
}

function Start-Loop([array]$game_frame, [array]$ship_frame){
    do {
        # Update the Frame
        # Test frame
        $game_frame = Update-Game $game_frame

        # Update the ship frame
        $return_obj = Update-Ship $game_frame $ship_frame

        Write-GameFrame $return_obj[0]
        $line = "- - - - - - - - - - - -"
        Write-Host $line
        Write-ShipFrame $return_obj[1]

        $game_frame = $return_obj[0]
        $ship_frame = $return_obj[1]

        # $global:game_over = $true
        # $game_frame = $return_obj[0]
        # $game_frame = $return_obj[1]

        $test = Read-Host "Proceed to next Frame?"
        Write-Host $test

    } until ($global:game_over)
}

function Update-Game([array]$game_frame){
    #  Loop for updating Aliens and Clearing hits Bottom up Order

    Write-Host "Frame before Update"
    Write-GameFrame $game_frame
    
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

    Write-Host "Frame post shot move"
    Write-GameFrame $game_frame

    # After moving or clearing everything we need to add a new Alien
    if($global:aliens_left_to_spawn -gt 0){
        $game_frame = Add-Alien $game_frame
        $global:aliens_left_to_spawn--
    }

    Write-Host "Frame After Update"
    Write-GameFrame $game_frame 

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

    Write-Host "Frame before Update"
    Write-ShipFrame $ship_frame 

    $shot_fired = $false
    $left_key = [ConsoleKey]::LeftArrow
    $right_key = [ConsoleKey]::RightArrow
    $spacebar = [ConsoleKey]::Spacebar

    do {
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
        Write-Host "Frame post Update"
        Write-ShipFrame $ship_frame
    } until ($shot_fired)


    Write-Host "Frame After Shot"
    Write-ShipFrame $ship_frame 

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


function Write-GameFrame([array]$game_frame){
    for ($row = 0; $row -lt $global:game_frame_height; $row++) {
        Write-Host $game_frame[$row]
    }
}

function Write-ShipFrame([array]$ship_frame){
    Write-Host $ship_frame
}

function Write-Score{
    # return $game_frame
}

Start-Game