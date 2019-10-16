module.exports = {
    'parserOptions': {
        'ecmaVersion': 5
    },
    'env': {
        'browser': true,
        'jquery': true
    },
    'plugins': [
        'compat'
    ],
    'extends': 'eslint:recommended',
    'rules': {
        'compat/compat': 'error',
        'valid-jsdoc': 'warn',
        'default-case': 'error',
        'eqeqeq': [
            'error',
            'smart'
        ],
        'no-magic-numbers': [
            'error',
            {
                'ignoreArrayIndexes': true,
                'ignore': [
                    -1,
                    0,
                    1
                ]
            }
        ],
        'comma-dangle': [
            'error',
            'never',
        ],
        "indent": [
            "error",
            4,
        ],
        "quotes": [
            "error",
            "single",
        ],
        "dot-notation": ["warn"],
        "object-shorthand": ["error", "never"],
        "linebreak-style": [
            "error",
            "unix",
        ],
        "no-implicit-globals": "error",
        "no-return-assign": "error",
        "no-throw-literal": "error",
        "strict": ["error", "function"],
        "require-jsdoc": ["error", {
        "require": {
            "FunctionDeclaration": true,
            "MethodDefinition": true,
            "ClassDeclaration": false,
            "ArrowFunctionExpression": false
        }
    }]
    },
};
