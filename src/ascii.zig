pub fn isAsciiLetterOrUnderscore(char: u8) bool {
    const valid_chars = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_";
    for (valid_chars) |c| {
        if (char == c) return true else continue;
    }
    return false;
}

pub fn isDigit(char: u8) bool {
    const valid_chars = "0123456789";
    for (valid_chars) |c| {
        if (char == c) return true else continue;
    }
    return false;
}

pub fn isSymbol(char: u8) bool {
    const valid_chars = "+-*/<>=!?@:,.";
    for (valid_chars) |c| {
        if (char == c) return true else continue;
    }
    return false;
}

pub fn isWhiteSpace(char: u8) bool {
    const valid_chars = " \t\r";
    for (valid_chars) |c| {
        if (char == c) return true else continue;
    }
    return false;
}
