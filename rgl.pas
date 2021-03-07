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
        melee, range: integer;
    end;

    freakClass = (Demented, Hunter);
    pfreak = ^freak;
    freak = record
        x, y: integer;
        s: char;
        class: freakClass;
        hp: integer;
        melee: integer;
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

procedure gameOver();
begin
    clrscr;
    GotoXY((ScreenWidth - 9) div 2, ScreenHeight div 2);
    write('Game Over');
    delay(2000);
    clrscr;
    halt(1);
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

    y := 2;
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
                    c.s := last^.data[x];
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
                    tf^.melee := 6;
                    tf^.s := last^.data[x];
                    last^.data[x] := ' ';
                    case tf^.s of
                        'D':
                        begin
                            tf^.class := Demented;
                            new(tg);
                            tg^.next := g;
                            tg^.x := x;
                            tg^.y := y;
                            g := tg;
                        end;
                        'H':
                        begin
                            tf^.class := Hunter;
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

procedure showMap(var m: pmap);
var
    tm: pmap;
    y: integer;
begin
    y := 2;
    while m <> nil do
    begin
        GotoXY(1, y);
        write(m^.data);
        tm := m;
        m := m^.next;
        dispose(tm);
        y += 1;
    end;
end;

procedure clearHappen();
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
    c.hp := 100;
    c.melee := 5;
    c.range := 7;
    TextColor(yellow);
    randomize;
end;
{ /Init }

{ FOV }
function isCharacter(c: character; x, y: integer): boolean;
begin
    if (x = c.x) and (y = c.y) then
        isCharacter := true
    else
        isCharacter := false;
end;

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

procedure reversePath(var p: ppath);
var
    tp, rp: ppath;
begin
    rp := nil;
    while p <> nil do
    begin
        new(tp);
        tp^.next := rp;
        tp^.x := p^.x;
        tp^.y := p^.y;
        rp := tp;
        tp := p;
        p := p^.next;
        dispose(tp);
    end;
    p := rp;
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

function findFreak(var f: pfreak; x, y: integer; var res: pfreak): boolean;
var
    tmp: pfreak;
begin
    tmp := f;
    while tmp <> nil do
    begin
        if (x = tmp^.x) and (y = tmp^.y) then
        begin
            findFreak := true;
            res := tmp;
            exit;
        end;
        tmp := tmp^.next;
    end;
    findFreak := false;
    res := nil;
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
    delay(1000);
end;

procedure hitMsgF(dmg: integer; f: freak);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
    if dmg <= 0 then
    begin
        write(f.class, ' didn`t hit');
        exit;
    end;
    write(f.class, ' attacked. Damage ', dmg);
end;

procedure showF(f: freak);
begin
    GotoXY(f.x, f.y);
    write(f.s);
end;

procedure hideF(f: freak);
begin
    GotoXY(f.x, f.y);
    write(' ');
end;

procedure moveF(flr: floor; c: character; var f: freak);    { todo }
begin

end;

procedure combatF(flr: floor; var c: character; f: freak);
var
    chance, dmg: integer;
begin
    chance := random(25) + 1;    { chance for miss hit }
    if chance = 1 then
    begin
        hitMsgF(0, f);
        exit;
    end;

    dmg := f.melee - random(f.melee div 2);   { random damage }
    c.hp -= dmg;
    hitMsgF(dmg, f);
    if c.hp <= 0 then
        gameOver();
end;

procedure actionFreak(flr: floor; var c: character; var f: pfreak);
var
    tmpf: pfreak;
    i, j, x, y: integer;
    found: boolean;
begin
    tmpf := f;
    while tmpf <> nil do
    begin
        found := false;
        x := tmpf^.x - 1;
        y := tmpf^.y - 1;
        for i := 0 to 2 do
            for j := 0 to 2 do
                if isCharacter(c, x + j, y + i) then
                    found := true;
        if found then
            combatF(flr, c, tmpf^)
        else
            moveF(flr, c, tmpf^);
        tmpf := tmpf^.next;
    end;
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

procedure hitMsgC(dmg: integer; ch: char);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
    if dmg <= 0 then
    begin
        write('You didn`t hit');
        exit;
    end;
    case ch of
        'm': write('You attacked. Damage ', dmg);
        'r': write('You fired. Damage ', dmg);
    end;
    delay(1000);
end;

procedure showParam(c: character);
var
    i: integer;
begin
    for i := 1 to ScreenWidth do
    begin
        GotoXY(i, 1);
        write(' ');
    end;
    GotoXY(10, 1);
    write('hp: ', c.hp);
    write('     melee: ', c.melee);
    write('     range: ', c.range);
end;

procedure meleeC(c: character; var f: pfreak);
var
    t, tmp: pfreak;     { target freak } 
    i, j, x, y, chance, dmg: integer;
begin
    chance := random(25) + 1;    { chance for miss hit }
    if chance = 1 then
    begin
        hitMsgC(0, 'm');
        exit;
    end;

    t := nil;
    x := c.x - 1;
    y := c.y - 1;
    for i := 0 to 2 do
        for j := 0 to 2 do
            if findFreak(f, x + j, y + i, tmp) then
                t := tmp;
    if t = nil then     { if haven`t got target } 
    begin
        hitMsgC(0, 'm');
        exit;
    end;
    dmg := c.melee - random(c.melee div 2);   { random damage } 
    t^.hp -= dmg;
    hitMsgC(dmg, 'm');
    if t^.hp <= 0 then
    begin
        deadMsgF(t);
        removeF(f, t);
    end;
end;

procedure rangeC(flr: floor; c: character; var f: pfreak);
var
    t, tmp: pfreak;     { target freak } 
    i, j, x, y, chance, dmg: integer;
begin
    chance := random(25) + 1;    { chance for miss hit }
    if chance = 1 then
    begin
        hitMsgC(0, 'r');
        exit;
    end;

    t := nil;
    x := c.x;           
    y := c.y;
    for i := 1 to 4 do     { vertical }
        if not isWall(flr, x, y - i) then
        begin
            if findFreak(f, x, y - i, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    for i := 1 to 4 do
        if not isWall(flr, x, y + i) then
        begin
            if findFreak(f, x, y + i, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    for j := 1 to 4 do      { horizontal }
        if not isWall(flr, x + j, y) then
        begin
            if findFreak(f, x + j, y, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    for j := 1 to 4 do
        if not isWall(flr, x - j, y) then
        begin
            if findFreak(f, x - j, y, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    if t = nil then     { if haven`t got target } 
    begin
        hitMsgC(0, 'r');
        exit;
    end;
    dmg := c.range - random(c.range div 2);   { random damage } 
    t^.hp -= dmg;
    hitMsgC(dmg, 'r');
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
        'q', 'Q': rangeC(flr, c, f);
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
    showParam(c);
    while true do
    begin
        if KeyPressed then
        begin
            clearHappen();
            handleKey(flr, c, f);
            actionFreak(flr, c, f);
            showParam(c);
            checkFov(flr, c, f);
        end;
    end;
end.
