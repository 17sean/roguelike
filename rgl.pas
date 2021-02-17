program rglike;
uses crt, slib;
type
    pmap = ^map;
    map = record
        data: string;
        next: ^map;
    end;

    ppath = ^path;
    path = record
        x, y: integer;
        next: ^path;
    end;

    pground = ^ground;
    ground = record
        x, y: integer;
        next: ^ground;
    end;

    pdoor = ^door;
    door = record
        x, y: integer;
        next: ^door;
    end;
    
    pwall = ^wall;
    wall = record
        x, y: integer;
        next: ^wall;
    end;

    pbuilding = ^building;
    building = record
        x, y: integer;
        next: ^building;
    end;

    floor = record
        p: ppath;
        g: pground;
        d: pdoor;
        w: pwall;
        b: pbuilding;
    end;

    character = record
        s: char;    { Symbol }
        x, y: integer;
        hp: integer;
        money: integer;
    end;

procedure screenCheck();
begin
    if (ScreenHeight < 22) or (Screenwidth < 75) then
    begin
        clrscr;
        GotoXY((ScreenWidth - 15) div 2, ScreenHeight div 2);
        write('resize to 80x24');
        delay(2000);
        clrscr;
        halt(1);
    end;
end;

{ MAP }
procedure parseM(
                 var first: pmap;
                 var flr: floor;
                 var c: character);
var
    mfile: text;
    last: pmap;
    p, tp: ppath;
    g, tg: pground;
    d, td: pdoor;
    w, tw: pwall;
    b, tb: pbuilding;
    x, y: integer;
begin
    if not DFE('map.txt') then
        halt(1);

    y := 1;
    first := nil;
    p := nil;
    g := nil;
    d := nil;
    w := nil;
    b := nil;
    assign(mfile, 'map.txt');
    reset(mfile);
    while not EOF(mfile) do
    begin
        if first = nil then
        begin
            new(first);
            last := first;
        end
        else
        begin
            new(last^.next);
            last := last^.next;
        end;
        readln(mfile, last^.data);
        x := 1;
        while last^.data[x] <> #0 do    { Check for floors }
        begin 
            case last^.data[x] of
                '@':
                begin
                    c.x := x;
                    c.y := y;
                    new(tp);
                    tp^.next := p;
                    tp^.x := x;
                    tp^.y := y;
                    p := tp;
                end;
                '#':
                begin
                    new(tp);
                    tp^.next := p;
                    tp^.x := x;
                    tp^.y := y;
                    p := tp;
                end;
                '.':
                begin
                    new(tg);
                    tg^.next := g;
                    tg^.x := x;
                    tg^.y := y;
                    g := tg;
                end;
                '+':
                begin
                    new(td);
                    td^.next := d;
                    td^.x := x;
                    td^.y := y;
                    d := td;
                end;
                '|', '-':
                begin
                    new(tw);
                    tw^.next := w;
                    tw^.x := x;
                    tw^.y := y;
                    w := tw;
                end;
                'b':
                begin
                    last^.data[x] := '.';
                    new(tb);
                    tb^.next := b;
                    tb^.x := x;
                    tb^.y := y;
                    b := tb;
                    new(tg);
                    tg^.next := g;
                    tg^.x := x;
                    tg^.y := y;
                    g := tg;
                end;
            end;
            x += 1;
        end;
        last^.next := nil;
        y += 1;
    end;
    close(mfile);
    flr.p := p;
    flr.g := g;
    flr.d := d;
    flr.w := w;
    flr.b := b;
end;

procedure showM(m: pmap);
var
    y: integer;
begin
    y := 1;
    while m <> nil do
    begin
        GotoXY(1, y);
        write(m^.data);
        m := m^.next;
        y += 1;
    end;
end;

{ /MAP }

{ FOV }
function isWall(flr: floor; x, y: integer): boolean;
begin
    while flr.w <> nil do
    begin
        if (x = flr.w^.x) and (y = flr.w^.y) then
        begin
            isWall := true;
            exit;
        end;
        flr.w := flr.w^.next;
    end;
    while flr.d <> nil do
    begin
        if (x = flr.d^.x) and (y = flr.d^.y) then
        begin
            isWall := true;
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    isWall := false
end;

function isBuilding(flr: floor; x, y: integer; res: building)
                                                        : boolean;
begin
    while flr.b <> nil do
    begin
        if (x = flr.b^.x) and (y = flr.b^.y) then
        begin
            isBuilding := true;
            res := flr.b^;
            exit;
        end;
        flr.b := flr.b^.next;
    end;
    isBuilding := false;
end;

function findB(flr: floor; c: character; var res: building)
                                                        : boolean;
var
    x, y: integer;
begin
    x := c.x;
    y := c.y;
    while not isWall(flr, c.x, y) do     { top }
    begin
        while not isWall(flr, x, y) do       { left }
        begin
            if isBuilding(flr, x, y, res) then
            begin
                findB := true;
                exit;
            end;
            x -= 1;
        end; 
        x := c.x;
        while not isWall(flr, x, y) do       { right }
        begin
            if isBuilding(flr, x, y, res) then
            begin
                findB := true;
                exit;
            end;
            x += 1;
        end;
        y -= 1;
    end;
    x := c.x;
    y := c.y + 1;
    while not isWall(flr, c.x, y) do     { bottom }
    begin
        while not isWall(flr, x, y) do       { left }
        begin
            if isBuilding(flr, x, y, res) then
            begin
                findB := true;
                exit;
            end;
            x -= 1;
        end; 
        x := c.x;
        while not isWall(flr, x, y) do       { right }
        begin
            if isBuilding(flr, x, y, res) then
            begin
                findB := true;
                exit;
            end;
            x += 1;
        end;
        y += 1;
    end;
end;

procedure showFov(); { todo }
{ for realization i need to know coordinates of monsters and iteams for compare }
{ need count what applies to the building and show it if compare give true }
begin

end;

procedure hideFov(flr: floor);
var
    x, y: integer;
begin
    while flr.b <> nil do
    begin
        x := flr.b^.x;
        y := flr.b^.y;
        while not isWall(flr, flr.b^.x, y) do     { top }
        begin
            while not isWall(flr, x, y) do       { left }
            begin
                GotoXY(x, y);
                write(' ');
                x -= 1;
            end; 
            x := flr.b^.x;
            while not isWall(flr, x, y) do       { right }
            begin
                GotoXY(x, y);
                write(' ');
                x += 1;
            end;
            y -= 1;
        end;
        x := flr.b^.x;
        y := flr.b^.y + 1;
        while not isWall(flr, flr.b^.x, y) do     { bottom }
        begin
            while not isWall(flr, x, y) do       { left }
            begin
                GotoXY(x, y);
                write(' ');
                x -= 1;
            end; 
            x := flr.b^.x;
            while not isWall(flr, x, y) do       { right }
            begin
                GotoXY(x, y);
                write(' ');
                x += 1;
            end;
            y += 1;
        end;
        flr.b := flr.b^.next;
    end;
end;

procedure checkFov(flr: floor; c: character); { todo }
{ i have bug with findB so i need to debug it }
var
    resb: building;     { result building }
begin
    {
    hideFov(flr);
    if findB(flr, c, resb) then
        writeln('yeah i found');
    }
    if ((c.x = flr.b^.x) and (c.y = flr.b^.y)) then  { just temp for example }
        hideFov(flr);
end;
{ /FOV }

{ Character }
procedure showC(c: character);
begin
    GotoXY(c.x, c.y);
    write(c.s);
end;

procedure hideC(c: character; loc: char);
begin
    GotoXY(c.x, c.y);
    write(loc);
end;

function canIMove(flr: floor; c: character; ch: char): boolean;
begin
    case ch of      { count x, y }
        'w': c.y -= 1;
        'a': c.x -= 1;
        's': c.y += 1;
        'd': c.x += 1;
    end;
    while flr.p <> nil do       { Check path }
    begin
        if (flr.p^.x = c.x) and (flr.p^.y = c.y) then
        begin
            CanIMove := true;
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    while flr.g <> nil do       { Check ground }
    begin
        if (flr.g^.x = c.x) and (flr.g^.y = c.y) then
        begin
            CanIMove := true;
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    while flr.d <> nil do       { Check door }
    begin
        if (flr.d^.x = c.x) and (flr.d^.y = c.y) then
        begin
            CanIMove := true;
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    canIMove := false;
end;

function whereAmI(flr: floor; c: character): char;
begin
    while flr.b <> nil do
    begin
        if (c.x = flr.b^.x) and (c.y = flr.b^.y) then
        begin
            whereAmI := ' ';
            exit;
        end;
        flr.b := flr.b^.next;
    end;
    while flr.p <> nil do
    begin
        if (c.x = flr.p^.x) and (c.y = flr.p^.y) then
        begin
            whereAmI := '#';
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    while flr.g <> nil do
    begin
        if (c.x = flr.g^.x) and (c.y = flr.g^.y) then
        begin
            whereAmI := '.';
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    while flr.d <> nil do
    begin
        if (c.x = flr.d^.x) and (c.y = flr.d^.y) then
        begin
            whereAmI := '+';
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    WhereAmI := #0;
end;

procedure moveC(flr: floor; var c: character; ch: char);
var
    loc: char;      { Location }
begin
    if not canIMove(flr, c, ch) then
        exit;
    loc := whereAmI(flr, c);
    hideC(c, loc);
    case ch of
        'w': c.y -= 1;
        'a': c.x -= 1;
        's': c.y += 1;
        'd': c.x += 1;
    end;
    showC(c);
end;

procedure handleKey(flr: floor; var c: character);
var
    ch: char;
begin
    ch := ReadKey;
    case ch of
        'w','a','s','d': moveC(flr, c, ch);
        #27:
        begin 
            clrscr;
            halt;
        end;
    end;
end;
{ /Character }

procedure init(
                var m: pmap;
                var flr: floor;
                var c: character);
begin
    parseM(m, flr, c);
    c.s := '@';
end;

var
    m: pmap;
    flr: floor;
    c: character;
begin
    screenCheck();
    clrscr;
    init(m, flr, c);
    showM(m);
    checkFov(flr, c);
    while true do
    begin
        if KeyPressed then
        begin
            handleKey(flr, c);
            checkFov(flr, c);
        end;
    end;
end.
