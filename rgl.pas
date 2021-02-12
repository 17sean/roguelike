program rglike;
uses crt, slib;
type
    pmap = ^map;
    map = record
        data: string;
        next: ^map;
    end;

    pfloor = ^floor;
    floor = record
        x, y: integer;
        next: ^floor;
    end;

    character = record
        s: char;    { Symbol }
        x, y: integer;
        hp: integer;
        money: integer;
    end;

procedure ScreenCheck();
begin
    if (ScreenHeight < 20) or (Screenwidth < 75) then
    begin
        clrscr;
        GotoXY((ScreenWidth div 2) - 15, ScreenHeight div 2);
        write('resize to 80x24');
        delay(2000);
        clrscr;
        halt(1);
    end;
end;

{ MAP }
procedure parseM(var first: pmap; var flr: pfloor; var c: character);
var
    mfile: text;
    last: pmap;
    tmpflr: pfloor;
    x, y: integer;
begin
    if not DFE('map.txt') then
        halt(1);

    y := 1;
    first := nil;
    flr := nil;
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
        begin { todo composite into case }
            if last^.data[x] in ['#', '.', '+'] then
            begin
                new(tmpflr);
                tmpflr^.next := flr;
                tmpflr^.x := x;
                tmpflr^.y := y;
                flr := tmpflr;
            end;
            if last^.data[x] = '@' then
            begin
                c.x := x;
                c.y := y;
            end;
            x += 1;
        end;
        last^.next := nil;
        y += 1;
    end;
    close(mfile);
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

function isXYfree(flr: pfloor; x, y: integer): boolean;
begin
    while flr <> nil do
    begin
        if (flr^.x = x) and (flr^.y = y) then
        begin
            isXYfree := true;
            exit;
        end;
        flr := flr^.next;
    end;
    isXYfree := false;
end;
{ /MAP }

{ Character }
procedure showC(c: character);
begin
    GotoXY(c.x, c.y);
    write(c.s);
end;

procedure hideC(c: character);
begin
    GotoXY(c.x, c.y);
    write('.');
end;

procedure moveC(flr: pfloor; var c: character);
var
    ch: char;
begin
    hideC(c);
    ch := ReadKey;
    case ch of
        'w': if isXYfree(flr, c.x, c.y-1) then c.y -= 1;
        'a': if isXYfree(flr, c.x-1, c.y) then c.x -= 1;
        's': if isXYfree(flr, c.x, c.y+1) then c.y += 1;
        'd': if isXYfree(flr, c.x+1, c.y) then c.x += 1;
        #27:
        begin 
            clrscr;
            halt;
        end;
    end;
    showC(c);
end;
{ /Character }

procedure init(var m: pmap; var flr: pfloor; var c: character);
begin
    parseM(m, flr, c);
    c.s := '@';
end;

var
    m: pmap;
    flr: pfloor;
    c: character;
begin
    ScreenCheck();
    clrscr;
    init(m, flr, c);
    showM(m);
    while true do
    begin
        if KeyPressed then
            moveC(flr, c);
        delay(50);
    end;
end.
