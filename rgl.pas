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
        x, y: integer;
        s: char;    { Symbol }
        hp: integer;
        money: integer;
    end;

    freakClass = (demented, hunter);

    pfreak = ^freak;
    freak = record
        x, y: integer;
        s: char;
        class: freakClass;
        hp: integer;
        next: ^freak;
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
procedure parseMap(
                   var first: pmap;
                   var flr: floor;
                   var c: character;
                   var f: pfreak);
var
    mfile: text;
    last: pmap;
    p, tp: ppath;
    g, tg: pground;
    d, td: pdoor;
    w, tw: pwall;
    b, tb: pbuilding;
    tf: pfreak;
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
    f := nil;
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
                    last^.data[x] := ' ';
                    new(tp);
                    tp^.next := p;
                    tp^.x := x;
                    tp^.y := y;
                    p := tp;
                end;
                '.':
                begin
                    last^.data[x] := ' ';
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
                    last^.data[x] := ' ';
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
                'D', 'H':
                begin
                    new(tf);
                    tf^.next := f;
                    tf^.x := x;
                    tf^.y := y;
                    tf^.hp := 100;
                    tf^.s := last^.data[x];
                    last^.data[x] := ' ';
                    case tf^.s of
                        'D':
                        begin
                            tf^.class := demented;
                            new(tg);
                            tg^.next := g;
                            tg^.x := x;
                            tg^.y := y;
                            g := tg;
                        end;
                        'H':
                        begin
                            tf^.class := hunter;
                            new(tp);
                            tp^.next := p;
                            tp^.x := x;
                            tp^.y := y;
                            p := tp;
                        end;
                    end;
                    f := tf;
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

procedure showMap(m: pmap);
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

{ Init }
procedure init(
               var m: pmap;
               var flr: floor;
               var c: character;
               var f: pfreak);
begin
    parseMap(m, flr, c, f);
    c.s := '@';
    c.hp := 100;
    TextColor(yellow);
end;
{ /Init }

{ FOV }
function isPath(flr: floor; x, y: integer): boolean;
begin
    while flr.p <> nil do
    begin
        if (x = flr.p^.x) and (y = flr.p^.y) then
        begin
            isPath := true;
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    isPath := false;
end;

function isGround(flr: floor; x, y: integer): boolean;
begin
    while flr.g <> nil do
    begin
        if (x = flr.g^.x) and (y = flr.g^.y) then
        begin
            isGround := true;
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    isGround := false;
end;

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

function isBuilding(flr: floor; x, y: integer): boolean;
begin
    while flr.b <> nil do
    begin
        if (x = flr.b^.x) and (y = flr.b^.y) then
        begin
            isBuilding := true;
            exit;
        end;
        flr.b := flr.b^.next;
    end;
    isBuilding := false;
end;

function isFreak(f: pfreak; x, y: integer; var ch: char): boolean;
begin
    while f <> nil do
    begin
        if (x = f^.x) and (y = f^.y) then
        begin
            isFreak := true;
            ch := f^.s;
            exit;
        end;
        f := f^.next;
    end;
    isFreak := false;
end;

function findBuilding(flr: floor; c: character): boolean;
var
    x, y: integer;
begin
    if not isGround(flr, c.x, c.y) then
    begin
        findBuilding := false;
        exit;
    end;

    y := c.y;
    while not isWall(flr, c.x, y) do     { top }
    begin
        x := c.x;
        while not isWall(flr, x, y) do       { left }
        begin
            if isBuilding(flr, x, y) then
            begin
                findBuilding := true;
                exit;
            end;
            x -= 1;
        end; 
        x := c.x + 1;
        while not isWall(flr, x, y) do       { right }
        begin
            if isBuilding(flr, x, y) then
            begin
                findBuilding := true;
                exit;
            end;
            x += 1;
        end;
        y -= 1;
    end;
    y := c.y + 1;
    while not isWall(flr, c.x, y) do     { bottom }
    begin
        x := c.x;
        while not isWall(flr, x, y) do       { left }
        begin
            if isBuilding(flr, x, y) then
            begin
                findBuilding := true;
                exit;
            end;
            x -= 1;
        end; 
        x := c.x + 1;
        while not isWall(flr, x, y) do       { right }
        begin
            if isBuilding(flr, x, y) then
            begin
                findBuilding := true;
                exit;
            end;
            x += 1;
        end;
        y += 1;
    end;
end;

procedure addFlrIns(var flrIns: pground; x, y: integer);
var
    tflrIns: pground;
begin
    new(tflrIns);
    tflrIns^.next := flrIns;
    tflrIns^.x := x;
    tflrIns^.y := y;
    flrIns := tflrIns;
end;

function isInFlrIns(flrIns: pground; x, y: integer): boolean;
begin
    while flrIns <> nil do
    begin
        if (x = flrIns^.x) and (y = flrIns^.y) then
        begin
            isInFlrIns := true;
            exit;
        end;
        flrIns := flrIns^.next;
    end;
    isInFlrIns := false;
end;

procedure addPath(var p: ppath; x, y: integer);
var
    tp: ppath;
begin
    new(tp);
    tp^.next := p;
    tp^.x := x;
    tp^.y := y;
    p := tp;
end;

procedure showPath(flr: floor; c: character; f: pfreak);
var
    tp, p: ppath;
    ch: char;
begin
    p := nil;
    addPath(p, c.x, c.y - 1);   { top }
    addPath(p, c.x - 1, c.y);   { left }
    addPath(p, c.x, c.y + 1);   { bottom }
    addPath(p, c.x + 1, c.y);   { right }
    tp := p;
    while tp <> nil do
    begin
        if isPath(flr, tp^.x, tp^.y) then
        begin
            GotoXY(tp^.x, tp^.y);
            write('#');
        end;
        tp := tp^.next;
    end;
    tp := p;
    while f <> nil do
    begin
        if isFreak(f, p^.x, p^.y, ch) then
        begin
            GotoXY(p^.x, p^.y);
            write(ch);
        end;
        f := f^.next;
    end;
end;

procedure showBuilding(flr: floor; c: character; f: pfreak); { todo show items }
var
    flrIns: pground;
    x, y: integer;
    ch: char;
begin
    flrIns := nil;
    y := c.y;
    { count all x, y in building }
    while not isWall(flr, c.x, y) do     { top }
    begin
        x := c.x;
        while not isWall(flr, x, y) do         { left }
        begin
            addFlrIns(flrIns, x, y);
            x -= 1;
        end; 
        x := c.x + 1;
        while not isWall(flr, x, y) do         { right }
        begin
            addFlrIns(flrIns, x, y);
            x += 1;
        end;
        y -= 1;
    end;
    y := c.y + 1;
    while not isWall(flr, c.x, y) do     { bottom }
    begin
        x := c.x;
        while not isWall(flr, x, y) do          { left }
        begin
            addFlrIns(flrIns, x, y);
            x -= 1;
        end; 
        x := c.x + 1;
        while not isWall(flr, x, y) do          { right }
        begin
            addFlrIns(flrIns, x, y);
            x += 1;
        end;
        y += 1;
    end;

    { show all that inside building }
    while flr.g <> nil do
    begin
        GotoXY(flr.g^.x, flr.g^.y);
        write('.');
        if isFreak(f, flr.g^.x, flr.g^.y, ch) then
            write(ch);
        flr.g := flr.g^.next;
    end;
    GotoXY(c.x, c.y);
    write(c.s);
end;

procedure hideBuilding(flr: floor);
var
    x, y: integer;
begin
    while flr.b <> nil do
    begin
        y := flr.b^.y;
        while not isWall(flr, flr.b^.x, y) do   { top }
        begin
            x := flr.b^.x;
            while not isWall(flr, x, y) do          { left }
            begin
                GotoXY(x, y);
                write(' ');
                x -= 1;
            end; 
            x := flr.b^.x + 1;
            while not isWall(flr, x, y) do          { right }
            begin
                GotoXY(x, y);
                write(' ');
                x += 1;
            end;
            y -= 1;
        end;
        y := flr.b^.y + 1;
        while not isWall(flr, flr.b^.x, y) do   { bottom }
        begin
            x := flr.b^.x;
            while not isWall(flr, x, y) do          { left }
            begin
                GotoXY(x, y);
                write(' ');
                x -= 1;
            end; 
            x := flr.b^.x + 1;
            while not isWall(flr, x, y) do          { right }
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

procedure checkFov(flr: floor; c: character; f: pfreak);
begin
 { todo itemsfinding(items for first after ground or path) }
    showPath(flr, c, f);
    if findBuilding(flr, c) then
        showBuilding(flr, c, f)
    else
        hideBuilding(flr);
end;
{ /FOV }

{ Character }
function canIMove(flr: floor; c: character; ch: char): boolean;
begin
    case ch of      { count x, y }
        'w', 'W': c.y -= 1;
        'a', 'A': c.x -= 1;
        's', 'S': c.y += 1;
        'd', 'D': c.x += 1;
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

procedure moveC(flr: floor; var c: character; ch: char);
var
    loc: char;      { Location }
begin
    if not canIMove(flr, c, ch) then
        exit;
    loc := whereAmI(flr, c);
    hideC(c, loc);
    case ch of
        'w', 'W': c.y -= 1;
        'a', 'A': c.x -= 1;
        's', 'S': c.y += 1;
        'd', 'D': c.x += 1;
    end;
    showC(c);
end;

procedure handleKey(flr: floor; var c: character; var f: pfreak);
var
    ch: char;
begin
    ch := ReadKey;
    case ch of
        'w','W','a','A','s','S','d','D': moveC(flr, c, ch);
        #27:
        begin 
            clrscr;
            halt;
        end;
    end;
end;
{ /Character }

var
    m: pmap;
    flr: floor;
    c: character;
    f: pfreak;
begin
    screenCheck();
    clrscr;
    init(m, flr, c, f);
    showMap(m);
    checkFov(flr, c, f);
    while true do
    begin
        if KeyPressed then
        begin
            handleKey(flr, c, f);
            checkFov(flr, c, f);
        end;
    end;
end.
