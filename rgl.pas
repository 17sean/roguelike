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

    pitem = ^item;
    item = record
        idx: integer;
        name: string;
        dmg: integer;
        dist: integer;
        strength: integer;
        next: ^item;
    end;

    shop = record
        x, y: integer;
        heal: integer;
        gun: integer;
        healcost, guncost: integer;
    end;

    floor = record
        p: ppath;
        g: pground;
        d: pdoor;
        w: pwall;
        b: pbuilding;
        s: shop;
    end;

    character = record
        stage: integer;
        x, y: integer;
        s: char;
        hp: integer;
        money: integer;
        dmg: integer;
        melee, range: item;
    end;

    freakClass = (Demented, Hunter);
    pfreak = ^freak;
    freak = record
        x, y: integer;
        s: char;
        class: freakClass;
        hp: integer;
        dmg: integer;
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
    delay(500);
    clrscr;
    halt(1);
end;

{ MAP }
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
    i, j: integer;
begin
    for i := 1 to 2 do
    begin
        GotoXY(1, ScreenHeight - i);
        for j := 1 to ScreenWidth do
            write(' ');
    end;
end;
{ /MAP }

{ Items }
function getItemByIdx(itm: pitem; idx: integer): item;
begin
    while itm <> nil do
    begin
        if (idx = itm^.idx) then
        begin
            getItemByIdx := itm^;
            exit;
        end;
        itm := itm^.next;
    end;
end;

procedure loadGun(itm: pitem; var c: character; idx: integer);
begin
    if idx <= 3 then
        c.melee := getItemByIdx(itm, idx)
    else
        c.range := getItemByIdx(itm, idx);
end;

procedure unloadMelee(itm: pitem; var c: character);
begin
    c.melee := getItemByIdx(itm, 0);
end;

procedure unloadRange(itm: pitem; var c: character);
begin
    c.range := getItemByIdx(itm, 0);
end;
{ /Items }

{ Parsers }
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
                '$':
                begin
                    last^.data[x] := ' ';
                    flr.s.x := x;
                    flr.s.y := y;
                end;
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
                'D', 'H':
                begin
                    new(tf);
                    tf^.next := f;
                    tf^.x := x;
                    tf^.y := y;
                    tf^.hp := 10;
                    tf^.dmg := 10;
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

procedure parseItems(var itm: pitem);
var
    ifile: text;
    titm: pitem;
    s: string;
begin
    assign(ifile, 'items.txt');
    reset(ifile);
    itm := nil;
    while not EOF(ifile) do
    begin
        readln(ifile, s);
        case ParseHeader(s) of
            '~':
            begin
                new(titm);
                titm^.next := itm;
            end;
            '#': itm := titm;
            'idx': titm^.idx := SrI(ParseBody(s));
            'name': titm^.name := ParseBody(s);
            'dmg': titm^.dmg := SrI(ParseBody(s));
            'distance': titm^.dist := SrI(ParseBody(s));
            'strength': titm^.strength := SrI(ParseBody(s));
        end;
    end;
    close(ifile);
end;

procedure createSave();
var
    sfile: text;
begin
    assign(sfile, 'save.txt');
    rewrite(sfile);
    writeln(sfile, 'stage:1;');
    writeln(sfile, 'hp:100;');
    writeln(sfile, 'dmg:2;');
    writeln(sfile, 'melee:0;');
    writeln(sfile, 'range:0;');
    close(sfile);
end;

procedure parseSave(itm: pitem; var c: character);
var
    sfile: text;
    s: string;
begin
    if not DFE('save.txt') then
        createSave();
    assign(sfile, 'save.txt');
    reset(sfile);
    while not EOF(sfile) do
    begin
        readln(sfile, s);
        case ParseHeader(s) of
            'stage': c.stage := SrI(ParseBody(s));
            'hp': c.hp := SrI(ParseBody(s));
            'money': c.money := SrI(ParseBody(s));
            'dmg': c.dmg := SrI(ParseBody(s));
            'melee': loadGun(itm, c, SrI(ParseBody(s)));
            'range': loadGun(itm, c, SrI(ParseBody(s)));
        end;
    end;
    close(sfile);
end;
{ /Parsers }

{ Init }
procedure init(
               var m: pmap;
               var flr: floor;
               var itm: pitem;
               var c: character;
               var f: pfreak);
begin
    parseMap(m, flr, c, f);
    parseItems(itm);
    write('ok');
    parseSave(itm, c);
    flr.s.heal := c.stage * 5;
    if flr.s.heal > 100 then
        flr.s.heal := 100;
    flr.s.gun := random(itm^.idx)+1;
    flr.s.healcost := c.stage * 10;
    flr.s.guncost := (c.stage + getItemByIdx(itm, flr.s.gun).dmg) * 10;
    TextColor(yellow);
    randomize;
end;
{ /Init }

{ FOV }
function whatXY(flr: floor; x, y: integer): char;
begin
    if (x = flr.s.x) and (y = flr.s.y) then
    begin
        whatXY := '$';
        exit;
    end;
    while flr.d <> nil do
    begin
        if (x = flr.d^.x) and (y = flr.d^.y) then
        begin
            whatXY := '+';
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    while flr.p <> nil do
    begin
        if (x = flr.p^.x) and (y = flr.p^.y) then
        begin
            whatXY := '#';
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    while flr.g <> nil do
    begin
        if (x = flr.g^.x) and (y = flr.g^.y) then
        begin
            whatXY := '.';
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    whatXY := #0;
end;

function isCharacter(c: character; x, y: integer): boolean;
begin
    if (x = c.x) and (y = c.y) then
        isCharacter := true
    else
        isCharacter := false;
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

procedure showPath(flr: floor; c: character; f: pfreak);
var
    ch: char;
    i, j, x, y: integer;
begin
    x := c.x - 1;
    y := c.y - 1;
    for i := 0 to 2 do
        for j := 0 to 2 do
            if isPath(flr, x + j, y + i) then
            begin
                GotoXY(x + j, y + i);
                write('#');
            end;
    for i := 0 to 2 do
        for j := 0 to 2 do
            if isFreak(f, x + j, y + i, ch) then
            begin
                GotoXY(x + j, y + i);
                write(ch);
            end;
    GotoXY(c.x, c.y);
    write(c.s);
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

procedure showBuilding(flr: floor; c: character; f: pfreak); { todo function for search what inside building }
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
            if (x = flr.s.x) and (y = flr.s.y) then
            begin
                GotoXY(x, y);
                write('$');
            end;
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
            if (x = flr.s.x) and (y = flr.s.y) then
            begin
                GotoXY(x, y);
                write('$');
            end;
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
            if (x = flr.s.x) and (y = flr.s.y) then
            begin
                GotoXY(x, y);
                write('$');
            end;
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
            if (x = flr.s.x) and (y = flr.s.y) then
            begin
                GotoXY(x, y);
                write('$');
            end;
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

{ Shop }
procedure shopInterface(flr: floor; itm: pitem);
var
    x, y: integer;
begin
    x := (ScreenWidth - 23) div 3;
    y := ScreenHeight - 2;
    GotoXY(x, y);
    write('1) ', flr.s.heal, ' Heal: ', flr.s.healcost);
    GotoXY(x, y+1);
    write('2) ', getItemByIdx(itm, flr.s.gun).name, ': ', flr.s.guncost); 
end;

procedure shopMenu(flr: floor; itm: pitem; var c: character);
var
    ch: char;
    success: boolean;
begin
    success := false;
    shopInterface(flr, itm);
    ch := ReadKey;
    clearHappen();
    case ch of
        '1':
        begin
            if flr.s.healcost <= c.money then
            begin
                c.hp += flr.s.heal;
                if c.hp > 100 then
                    c.hp := 100;
                c.money -= flr.s.healcost;
                success := true;
            end;
        end;
        '2':
        begin
            if flr.s.guncost <= c.money then
            begin
                loadGun(itm, c, flr.s.gun);
                c.money -= flr.s.guncost;
                success := true;
            end;
        end;
        else
            exit;
    end;
    if success then
    begin
        GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
        write('Success');
        delay(1000);
    end
    else
    begin
        GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
        write('You haven`t enough money');
        delay(2000);
    end;
    clearHappen();
end;
{ /Shop }

{ Messages }
procedure hitMsgC(dmg: integer; mr, nc: char);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
    if dmg <= 0 then
    begin
        write('You didn`t hit');
        delay(1000);
        exit;
    end;
    if nc = 'c' then
    begin
        write('Critical hit! Damage ', dmg);
        exit;
    end;
    case mr of
        'm': write('You attacked. Damage ', dmg);
        'r': write('You fired. Damage ', dmg);
    end;
    delay(1000);
end;

procedure deadMsgC(f: freak);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 1);
    write('You died by ', f.class);
    delay(2000);
end;

procedure noGunMsgC();
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 1);
    write('You haven''t any gun');
    delay(2000);
end;

procedure brokenGunMsgC();
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 1);
    write('Your weapon is broken');
    delay(2000);
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
    delay(1000);
end;

procedure deadMsgF(t: pfreak);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 1);
    write(t^.class, ' is dead');
    delay(1000);
end;
{ /Messages }

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

function canFMove(flr: floor; c: character; all: pfreak; f: freak; ch: char)
                                                                    : boolean;
begin
    case ch of      { count x, y }
        'w': f.y -= 1;
        'a': f.x -= 1;
        's': f.y += 1;
        'd': f.x += 1;
    end;
    while all <> nil do          { Check freaks }
    begin
        if (f.x = all^.x) and (f.y = all^.y) then
        begin
            CanFMove := false;
            exit;
        end;
        all := all^.next;
    end;
    while flr.p <> nil do       { Check path }
    begin
        if (f.x = flr.p^.x) and (f.y = flr.p^.y) then
        begin
            CanFMove := true;
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    while flr.g <> nil do       { Check ground }
    begin
        if (f.x = flr.g^.x) and (f.y = flr.g^.y) then
        begin
            CanFMove := true;
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    while flr.d <> nil do       { Check door }
    begin
        if (f.x = flr.d^.x) and (f.y = flr.d^.y) then
        begin
            CanFMove := true;
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    canFMove := false;
end;

procedure moveF(flr: floor; c: character; all: pfreak; var f: freak);
var
    ch: char;
    i, j, x, y: integer;
    found: boolean;
begin
    if random(25) = 0 then   { chance for miss move }
        exit;

    found := false;
    x := f.x - 5;
    y := f.y - 5;
    for i := 0 to 10 do
        for j := 0 to 10 do
            if isCharacter(c, x + j, y + i) then
                found := true;
    if found then
    begin
        case random(2) of
            0:
                if f.y <> c.y then
                    if f.y > c.y then
                        ch := 'w'
                    else
                        ch := 's';
            1:
                if f.x <> c.x then
                    if f.x > c.x then
                        ch := 'a'
                    else
                        ch := 'd';
        end;
    end
    else
    begin
        case random(4) of
            0: ch := 'w';
            1: ch := 'a';
            2: ch := 's';
            3: ch := 'd';
        end;
    end;
    if canFMove(flr, c, all, f, ch) then
        case ch of
            'w': f.y -= 1;
            'a': f.x -= 1;
            's': f.y += 1;
            'd': f.x += 1;
        end;
end;

procedure combatF(flr: floor; var c: character; f: freak);
var
    dmg: integer;
begin
    if random(25) = 0 then    { chance for miss hit }
    begin
        hitMsgF(0, f);
        exit;
    end;

    dmg := f.dmg - random(f.dmg div 2);   { random damage }
    c.hp -= dmg;
    hitMsgF(dmg, f);
    if c.hp <= 0 then
    begin
        deadMsgC(f);
        gameOver();
    end;
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
            moveF(flr, c, f, tmpf^);
        tmpf := tmpf^.next;
    end;
end;
{ /Freak } 

{ Character }
function canIMove(flr: floor; itm: pitem; var c: character;
                                                f: pfreak; ch: char): boolean;
var
    x, y: integer;
begin
    x := c.x;
    y := c.y;
    case ch of      { count x, y }
        'w', 'W': y -= 1;
        'a', 'A': x -= 1;
        's', 'S': y += 1;
        'd', 'D': x += 1;
    end;
    if (x = flr.s.x) and (y = flr.s.y) then    { Shop }
    begin
        canIMove := false;
        shopMenu(flr, itm,c);
        exit;
    end;
    while f <> nil do          { Freaks }
    begin
        if (x = f^.x) and (y = f^.y) then
        begin
            canIMove := false;
            exit;
        end;
        f := f^.next;
    end;
    while flr.d <> nil do       { Door }
    begin
        if (x = flr.d^.x) and (y = flr.d^.y) then
        begin
            canIMove := true;
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    while flr.p <> nil do       { Path }
    begin
        if (x = flr.p^.x) and (y = flr.p^.y) then
        begin
            canIMove := true;
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    while flr.g <> nil do       { Ground }
    begin
        if (x = flr.g^.x) and (y = flr.g^.y) then
        begin
            canIMove := true;
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    canIMove := false;
end;

procedure showC(c: character);
begin
    GotoXY(c.x, c.y);
    write(c.s);
end;

procedure hideC(flr: floor; c: character);
var
    loc: char;
begin
    loc := whatXY(flr, c.x, c.y);
    GotoXY(c.x, c.y);
    write(loc);
end;

procedure moveC(flr: floor; itm: pitem; var c: character; f: pfreak; ch: char);
begin
    if not canIMove(flr, itm, c, f, ch) then
        exit;
    hideC(flr, c);
    case ch of
        'w', 'W': c.y -= 1;
        'a', 'A': c.x -= 1;
        's', 'S': c.y += 1;
        'd', 'D': c.x += 1;
    end;
    showC(c);
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
    GotoXY(5, 1);
    write('HP: ', c.hp);
    write('  Money: ', c.money);
    write('  Inv: ', c.melee.name);
    write(' and ', c.range.name);
    write('   M: ', c.melee.dmg + c.dmg);
    write(' S: ', c.melee.strength);
    write('   R: ', c.range.dmg);
    write(' S: ', c.range.strength);
end;

procedure meleeC(itm: pitem; var c: character; var f: pfreak);
var
    t, tmp: pfreak;     { target freak } 
    i, j, x, y, dmg: integer;
    nc: char;
begin
    if (c.melee.strength <= 0) and (c.melee.idx <> 0) then
    begin
        unloadMelee(itm, c);
        brokenGunMsgC();
    end;
    if c.melee.strength <> 0 then
        c.melee.strength -= 1;
    if random(25) = 0 then   { chance for miss hit }
    begin
        hitMsgC(0, 'm', 'n');
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
        hitMsgC(0, 'm', 'n');
        exit;
    end;
    dmg := c.dmg + c.melee.dmg - random(c.melee.dmg div 2);   { random damage }
    if random(25) = 0 then   { critical hit }
    begin
        dmg *= 2;
        nc := 'c';
    end
    else
        nc := 'n';
    t^.hp -= dmg;
    hitMsgC(dmg, 'm', nc);
    if t^.hp <= 0 then
    begin
        deadMsgF(t);
        removeF(f, t);
    end;
end;

procedure rangeC(flr: floor; itm: pitem; var c: character; var f: pfreak);
var
    t, tmp: pfreak;     { target freak } 
    i, j, x, y, dmg: integer;
    nc: char;
begin
    if (c.range.idx = 0) then
    begin
        noGunMsgC();
        exit;
    end;
    if (c.range.strength <= 0) and (c.range.idx <> 0) then
    begin
        unloadRange(itm, c);
        brokenGunMsgC();
        exit;
    end;
    if c.range.strength <> 0 then
        c.range.strength -= 1;
    if random(25) = 0 then   { chance for miss hit }
    begin
        hitMsgC(0, 'r', 'n');
        exit;
    end;

    t := nil;
    x := c.x - 1;           
    y := c.y - 1;
    for i := 0 to 2 do     { if near the player }
        for j := 0 to 2 do
            if findFreak(f, x + j, y + i, tmp) then
                t := tmp;
    x := c.x;           
    y := c.y;
    for i := 1 to c.range.dist do     { vertical }
        if not isWall(flr, x, y - i) then
        begin
            if findFreak(f, x, y - i, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    for i := 1 to c.range.dist do
        if not isWall(flr, x, y + i) then
        begin
            if findFreak(f, x, y + i, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    for j := 1 to c.range.dist do      { horizontal }
        if not isWall(flr, x + j, y) then
        begin
            if findFreak(f, x + j, y, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    for j := 1 to c.range.dist do
        if not isWall(flr, x - j, y) then
        begin
            if findFreak(f, x - j, y, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    if t = nil then     { if haven`t got target } 
    begin
        hitMsgC(0, 'r', 'n');
        exit;
    end;
    dmg := c.range.dmg - random(c.range.dmg div 2);   { random damage } 
    if random(25) = 0 then   { critical hit }
    begin
        dmg *= 2;
        nc := 'c';
    end
    else
        nc := 'n';
    t^.hp -= dmg;
    hitMsgC(dmg, 'r', nc);
    if t^.hp <= 0 then
    begin
        deadMsgF(t);
        removeF(f, t);
    end;
end;

procedure handleKey(flr: floor; itm: pitem; var c: character; var f: pfreak);
var
    ch: char;
begin
    ch := ReadKey;
    case ch of
        'w','W','a','A','s','S','d','D': moveC(flr, itm, c, f, ch);
        'e', 'E': meleeC(itm, c, f);
        'q', 'Q': rangeC(flr, itm, c, f);
        #27: gameOver();
    end;
end;
{ /Character }

var
    m: pmap;
    flr: floor;
    itm: pitem;
    c: character;
    f: pfreak;
begin
    clrscr;
    screenCheck();
    init(m, flr, itm, c, f);
    showMap(m);
    checkFov(flr, c, f);
    showParam(c);
    while true do
    begin
        if KeyPressed then
        begin
            clearHappen();
            handleKey(flr, itm, c, f);
            clearHappen();
            actionFreak(flr, c, f);
            showParam(c);
            checkFov(flr, c, f);
        end;
    end;
end.
