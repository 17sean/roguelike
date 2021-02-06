program rglike;
uses crt;
type

    character = record
        s: char;    { Symbol }
        x, y: integer;
{
        hp: integer;        TODO MAYBE 
        mana: integer;
        money: integer;
}
    end;

procedure init(var c: character);
begin
    c.s := '@';
    c.x := 5;
    c.y := 3;
end;

procedure showC(c: character);
begin
    GotoXY(c.x, c.y);
    write(c.s);
end;

procedure hideC(c: character);
begin
    GotoXY(c.x, c.y);
    write(' ');
end;

procedure moveC(var c: character);
var
    ch: char;
begin
    hideC(c);
    ch := ReadKey;
    case ch of
    'w': c.y -= 1;
    'a': c.x -= 1;
    's': c.y += 1;
    'd': c.x += 1;
    #27: halt;
    end;
    showC(c);
end;

var
    c: character;
begin
    clrscr;
    init(c);
    while true do
    begin
        if KeyPressed then
            moveC(c);
        delay(50);
    end;
end.
