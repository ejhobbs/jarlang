// Constructor
function BitString () {
    var tmp = [];

    for (var i = 0; i < arguments.length; i++) {
        if (!(ErlNumber.isErlNumber(arguments[i]) && arguments[i].isInteger()) && !List.isString(arguments[i])) {
            throw "bad argument";
        }

        if (List.isString(arguments[i])) {
            for (c in arguments[i].toString().split("")) {
                tmp.push(c.charCodeAt(0));
            }
        }
        else {
            var max8bit = (1 << 8) - 1;
            tmp.push(arguments[i].greaterThan(max8bit) ? max8bit : arguments[i].getValue().c[0]);
        }
    }

    this.value = Uint8Array.of(...tmp);
}

// Static Methods
BitString.isBitString = (bitstring) => bitstring instanceof BitString;
BitString.isBinary = (bitstring) => bitstring instanceof BitString; // todo

// Prototype Methods
BitString.prototype.value = function() {
    return this.value;
};

BitString.prototype.toString = function() {
    return `<<${this.value.join(",")}>>`;
};

BitString.prototype.isUnbound = function() {
    return false;
};

BitString.prototype.match = function(X) {
    if (BitString.isBitString(X) && this.value === X.value) {
        return true;
    }
    else {
        return false;
    }
};


if (typeof exports != "undefined") {
    exports.BitString = BitString;
}
