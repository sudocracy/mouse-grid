return (function ()

    local manifest = {  

        name = "Mouse Grid", 
        description = [[ Shows a 26 x 26 grid on the screen with a two-letter 
                         address for each cell. Typing the address will position 
                         the mouse in the center of that cell ]], 
        author = "sudocracy", 
        version = "0.1", 
        license = "0BSD", 
        homepage = "https://github.com/sudocracy"
    }

    local logging = true;
    local running = false;
    local hotkey = nil;

    local LOG_PREFIX = "🔥 | MOUSE-GRID  | "

    local function serialize(object)
            
        if (object) then
            return hs.inspect(object):gsub("\n", "")
        else
            return ""
        end

    end

    local function log(format, ...)
            
        if logging then
            local message = string.format(format, ... )
            print( LOG_PREFIX .. message)
        end
    end

    local function module() 
        
        local locations, bindings = {}, {}
        local currentScreen, screenRectangle, grid =  nil, nil, nil
        local selection = ''

        local lazy, guard, main

        local createMouseGrid,
              drawCell,
              drawGrid,
              getLowercaseLetterFromOrdinal,
              getNextScreenToMoveGridTo,
              getScreenToDrawGridOn,
              leftClickMouse,
              listenForMovementCommands,
              moveMouseCursor

        lazy = function(fn)

            return function(...) fn(...) end
        end

        guard = function(fn, defaultValue)

                local status, result = pcall(fn)

                if(status) then 
                return result 

            else 
                return defaultValue 
            end
        end

        getScreenToDrawGridOn = function()

            local function getFocusedWindowScreen() 
                return hs.window.focusedWindow():screen() 
            end
            
            local function getMouseScreen() 
                return hs.mouse.getCurrentScreen() 
            end

            local function getMainScreen() 
                return hs.screen.mainScreen() 
            end

            local function getPrimaryScreen() 
                return hs.screen.primaryScreen() 
            end

            local selectedScreen  = guard(getMainScreen, nil) or
                                    guard(getMouseScreen, nil)  or
                                    guard(getFocusedWindowScreen, nil) or
                                    guard(getPrimaryScreen, nil)
                                    
            if(selectedScreen == nil) then 
                
                error({ 
                    name = "Could not find a screen to place to draw the grid on.", 
                    message = "Could not find a screen to draw the grid on.", 
                    stack = debug.traceback()
                })   
            else
                return selectedScreen
            end

        end

        getNextScreenToMoveGridTo = function(currentScreen)

            local screens = hs.screen.allScreens()

            for index, screen in ipairs(screens) do

                if(screen:id() == currentScreen:id()) then  
                    local nextScreenIndex = (index % #screens) + 1
                    return screens[nextScreenIndex]
                end
            end
        end

        getLowercaseLetterFromOrdinal = function(ordinal)

            local letter = string.char(string.byte('a') - 1 + ordinal)
            return letter
        end

        moveMouseCursor = function(desiredLocation)
        
            local currentLocation = hs.mouse.absolutePosition()

            log("Current Mouse Location is: %s" , serialize(currentLocation) )
            log("Desired Mouse Location is: %s" , serialize(desiredLocation) )
            
            hs.mouse.absolutePosition(desiredLocation)
            
            local movedLocation = hs.mouse.absolutePosition()

            log("Moved Mouse Location is: %s" , serialize(movedLocation) )
        
        end

        leftClickMouse = function()

            local currentLocation = hs.mouse.absolutePosition()
            hs.eventtap.leftClick(currentLocation)

            log("Left Mouse Click at Location: %s" , serialize(currentLocation) )
        end

        drawCell = function(coordinates, dimensions)

            local label = getLowercaseLetterFromOrdinal(coordinates.x) .. getLowercaseLetterFromOrdinal(coordinates.y)
                    
            locations[label] = { 
                
                x = screenRectangle.x + dimensions.x + dimensions.w / 2,
                y = screenRectangle.y + dimensions.y + dimensions.h / 2 
            }

            grid:appendElements ({ 

                type = "rectangle", 
                action = "stroke", 
                strokeWidth = 4, 
                strokeColor = { red = 1  }, 
                frame = dimensions
            })

            grid:appendElements ({ 

                type = "text", 
                action = "fill", 
                frame = {                     
                    x = dimensions.x + dimensions.w / 8, 
                    y = dimensions.y + dimensions.h / 8, 
                    w = dimensions.w - dimensions.w / 8, 
                    h = dimensions.h - dimensions.h / 8, 
                },

                text = hs.styledtext.new(label, { 
                    color = { white = 1 },
                    alignment = "left",
                    font = { size = 18 }
                })
            })

        end

        drawGrid = function()

            local cells = 26 -- in each dimension

            local horizontalStep = screenRectangle.w / cells
            local verticalStep = screenRectangle.h / cells 

            grid:appendElements ({

                action = "fill",
                fillColor = { alpha = 0.7, blue = 0.5, green = 0.5  },
                frame = screenRectangle,
                type = "rectangle"
            })

            local currentCoordinates = { x = 1, y = 1 }

            for verticalCellNumber = 1, cells do

                for horizontalCellNumber = 1, cells do

                    local dimensions = { 

                        x = horizontalStep * (horizontalCellNumber - 1), 
                        y = verticalStep * (verticalCellNumber - 1), 
                        w = horizontalStep, 
                        h = verticalStep 
                    }

                    log("Dimensions: %s", serialize(dimensions))
                    drawCell (currentCoordinates, dimensions)

                    currentCoordinates.y = currentCoordinates.y + 1
                end

                currentCoordinates.y = 1
                currentCoordinates.x = currentCoordinates.x + 1
            end

            grid:show()

            return grid

        end

        listenForMovementCommands = function() 

            local numberOfkeysPressed = 0

            local function unbind ()
                for key, binding in ipairs(bindings) do
                    if binding == nil or binding.delete  == nil then 
                        return 
                    else
                        binding:delete()
                    end
                    
                end
            end

            local function destroyMouseGrid (mustContinueRunning)

                unbind()
                grid:delete()
                
                locations, bindings = {}, {}
                currentScreen, screenRectangle, grid =  nil, nil, nil
                selection = ''

                if(mustContinueRunning) then 
                    return 
                else
                    running = false
                end

            end

            local function bindOneLetter(letter)

                local function binder()
                                
                    numberOfkeysPressed = numberOfkeysPressed + 1
                    selection = selection .. letter 

                    log("Current Selection is '%s' after %d key presses.", selection, numberOfkeysPressed)

                    if(numberOfkeysPressed == 2) then 

                        moveMouseCursor(locations[selection])
                        destroyMouseGrid()
                        
                    end
                end

                local binding = hs.hotkey.bind('', letter, nil, binder)

                return binding
            end

            local function bindLetters()

                for ordinal = 1, 26 do 
                    letter = getLowercaseLetterFromOrdinal(ordinal)
                    table.insert(bindings, bindOneLetter(letter))
                end
            end

            local function bindEscapes()

                local escapeBinding = hs.hotkey.bind('', 'escape', nil,  destroyMouseGrid)

                -- Needed because we map ESC to CTRL-G in BetterTouchTool for Emacs. Without 
                -- this, the grid won't be dismissed when ESC is pressed when Emacs is the 
                -- foreground app.
                local emacsEscapeBinding = hs.hotkey.bind({'control'}, 'g', nil,  destroyMouseGrid)  

                table.insert(bindings, escapeBinding)         
                table.insert(bindings, emacsEscapeBinding)
                
            end

            local function bindMoveGridToAnotherScreen()

                table.insert(bindings, hs.hotkey.bind(hotkey.modifiers, hotkey.key, nil, function() 
                    
                    local nextScreen = getNextScreenToMoveGridTo(currentScreen)
                
                    destroyMouseGrid(true)
                    createMouseGrid(nextScreen)

                end))
            end

            local function bind()

                bindLetters()
                bindEscapes()
                bindMoveGridToAnotherScreen()
            end

            bind()

            return selection;

        end 

        createMouseGrid = function(screen)

            if(screen == nil) then
                screen = getScreenToDrawGridOn()
            end

            currentScreen = screen
            screenRectangle = screen:fullFrame()
            grid = hs.canvas.new(screenRectangle)

            drawGrid()
            listenForMovementCommands()
            
        end    

        main = function()

            if(running) then 
                log("Invoked while already running. Ignoring.")
                return
            else
                running = true
                createMouseGrid()
            end

        end
    
        main()
    end

    local function configure(desiredHotkey)

        if(desiredHotkey == nil or desiredHotkey.modifiers == nil or desiredHotkey.key == nil) then 
            error("Hotkey must be provided. Example: { modifiers = { 'cmd', 'ctrl' }, key = '1' }")
        else
            hotkey = desiredHotkey
            log("Hotkey is: %s", serialize(hotkey))
        end
    end

    return { 

        configure = configure, 
        run = module, 
        mainfest = manifest 
    }

end)()
