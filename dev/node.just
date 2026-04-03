# Node tools — installed via npm

[group('node')]
prettier:
    @echo "installing/upgrading prettier..."
    @{{ npm_install }} prettier

[group('node')]
eslint:
    @echo "installing/upgrading eslint..."
    @{{ npm_install }} eslint
