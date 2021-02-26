program roguelike;
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
        melee: integer;
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
    if (ScreenHeight < 23) or (Screenwidth < 76) then
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
                    tf^.hp := 10;
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

procedure clearHappen;
var
    i: integer;
begin
    GotoXY(1, ScreenHeight - 2);    { clear }
    for i := 1 to ScreenWidth do
        write(' ');
    GotoXY(1, ScreenHeight - 1);
    for i := 1 to ScreenWidth do
        write(' ');
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
    c.melee := 6;
    {
    TextColor(yellow);
    }
    randomize;
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

function isDoor(flr: floor; x, y: integer): boolean;
begin
    while flr.d <> nil do
    begin
        if (x = flr.d^.x) and (y = flr.d^.y) then
        begin
            isDoor := true;
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    isDoor := false;
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

function findFreak(f: pfreak; x, y: integer; var res: pfreak): boolean;
begin
    while f <> nil do
    begin
        if (x = f^.x) and (y = f^.y) then
        begin
            findFreak := true;
            res := f;
            exit;
        end;
        f := f^.next;
    end;
    findFreak := false;
    res := nil;
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
    i, j: integer;
begin
    p := nil;
    c.x -= 1;
    c.y -= 1;
    for i := 0 to 2 do
        for j := 0 to 2 do
            if not ((i = 1) and (j = 1)) then
                addPath(p, c.x + j, c.y + i);
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
    while tp <> nil do
    begin
        if isFreak(f, tp^.x, tp^.y, ch) then
        begin
            GotoXY(tp^.x, tp^.y);
            write(ch);
        end;
        tp := tp^.next;
    end;
end;

procedure showBuilding(flr: floor; c: character; f: pfreak);
var
    x, y: integer;
    ch: char;
begin
    y := c.y;
    { count all x, y in building }
    while not isWall(flr, c.x, y) do     { top }
    begin
        x := c.x;
        while not isWall(flr, x, y) do         { left }
        begin
            GotoXY(x, y);
            write('.');
            if isFreak(f, x, y, ch) then
            begin
                GotoXY(x, y);
                write(ch);
            end;
            x -= 1;
        end; 
        x := c.x + 1;
        while not isWall(flr, x, y) do         { right }
        begin
            GotoXY(x, y);
            write('.');
            if isFreak(f, x, y, ch) then
            begin
                GotoXY(x, y);
                write(ch);
            end;
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
            GotoXY(x, y);
            write('.');
            if isFreak(f, x, y, ch) then
            begin
                GotoXY(x, y);
                write(ch);
            end;
            x -= 1;
        end; 
        x := c.x + 1;
        while not isWall(flr, x, y) do          { right }
        begin
            GotoXY(x, y);
            write('.');
            if isFreak(f, x, y, ch) then
            begin
                GotoXY(x, y);
                write(ch);
            end;
            x += 1;
        end;
        y += 1;
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
    showPath(flr, c, f);
    if findBuilding(flr, c) then
        showBuilding(flr, c, f)
    else if isDoor(flr, c.x, c.y) then
        hideBuilding(flr);
end;
{ /FOV }

{ Freak }
procedure removeF(var f, t: pfreak);
var
    pp: ^pfreak;
begin
    pp := @f;
    while pp^ <> t do
        pp := @(pp^^.next);
    pp^ := pp^^.next;
    dispose(t);
end;

procedure deadMsgF(t: pfreak);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 1);
    write(t^.class, ' is dead');
end;
{ /Freak } 

{ Character }
function canIMove(flr: floor; c: character; f: pfreak; ch: char): boolean;
begin
    case ch of      { count x, y }
        'w', 'W': c.y -= 1;
        'a', 'A': c.x -= 1;
        's', 'S': c.y += 1;
        'd', 'D': c.x += 1;
    end;
    while f <> nil do          { Check freaks }
    begin
        if (c.x = f^.x) and (c.y = f^.y) then
        begin
            CanIMove := false;
            exit;
        end;
        f := f^.next;
    end;
    while flr.p <> nil do       { Check path }
    begin
        if (c.x = flr.p^.x) and (c.y = flr.p^.y) then
        begin
            CanIMove := true;
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    while flr.g <> nil do       { Check ground }
    begin
        if (c.x = flr.g^.x) and (c.y = flr.g^.y) then
        begin
            CanIMove := true;
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    while flr.d <> nil do       { Check door }
    begin
        if (c.x = flr.d^.x) and (c.y = flr.d^.y) then
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

procedure moveC(flr: floor; var c: character; f: pfreak; ch: char);
var
    loc: char;      { Location }
begin
    if not canIMove(flr, c, f, ch) then
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

procedure hitMsgC(dmg: integer);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
    if dmg > 0 then
        write('You attacked. Damage ', dmg)
    else
        write('You didn`t hit');
end;

procedure meleeC(c: character; var f: pfreak);
var
    p: ppath;
    t: pfreak;     { target freak } 
    i, j, chance, dmg: integer;
begin
    chance := random(25) + 1;    { chance for miss hit }
    if chance = 1 then
    begin
        hitMsgC(0);
        exit;
    end;
    dmg := c.melee - random(c.melee div 2);   { random damage } 
    p := nil;
    c.x -= 1;
    c.y -= 1;
    for i := 0 to 2 do
    begin
        for j := 0 to 2 do
            addPath(p, c.x + j, c.y + i);
    end;
    t := nil;
    while p <> nil do
    begin
        if findFreak(f, p^.x, p^.y, t) then
            break;
        p := p^.next;
    end;
    if t = nil then     { if haven`t got target } 
    begin
        hitMsgC(0);
        exit;
    end;
    t^.hp -= dmg;
    hitMsgC(dmg);
    if t^.hp <= 0 then
    begin
        deadMsgF(t);
        removeF(f, t);
    end;
end;

procedure rangeC(c: character; var f: pfreak);
var
    p: ppath;
    t: pfreak;     { target freak } 
    i, j, chance, dmg: integer;
begin
    chance := random(25) + 1;    { chance for miss hit }
    if chance = 1 then
    begin
        hitMsgC(0);
        exit;
    end;
    dmg := c.melee - random(c.melee div 2);   { random damage } 
    p := nil;
    c.x -= 1;
    c.y -= 1;
    for i := 0 to 2 do
    begin
        for j := 0 to 2 do
            addPath(p, c.x + j, c.y + i);
    end;
    t := nil;
    while p <> nil do
    begin
        if findFreak(f, p^.x, p^.y, t) then
            break;
        p := p^.next;
    end;
    if t = nil then     { if haven`t got target } 
    begin
        hitMsgC(0);
        exit;
    end;
    t^.hp -= dmg;
    hitMsgC(dmg);
    if t^.hp <= 0 then
    begin
        deadMsgF(t);
        removeF(f, t);
    end;
end;
procedure handleKey(flr: floor; var c: character; var f: pfreak);
var
    ch: char;
begin
    ch := ReadKey;
    case ch of
        'w','W','a','A','s','S','d','D': moveC(flr, c, f, ch);
        'e', 'E': meleeC(c, f);
        'q', 'Q': rangeC(c, f);
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
            clearHappen();
            handleKey(flr, c, f);
            checkFov(flr, c, f);
        end;
    end;
end.
