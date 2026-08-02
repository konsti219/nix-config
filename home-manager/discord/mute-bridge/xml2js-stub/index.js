function unsupported() {
    throw new Error(
        "xml2js is stubbed out in this build: dbus-native introspection is unavailable. " +
        "Use raw bus.invoke() messages, or vendor the real xml2js."
    );
}

class Parser {
    constructor() {
        unsupported();
    }
}

class Builder {
    constructor() {
        unsupported();
    }
}

module.exports = {
    Parser,
    Builder,
    parseString: unsupported,
    parseStringPromise: unsupported,
    processors: {},
    defaults: {}
};
