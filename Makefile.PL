use inc::Module::Install;
name 'WebService-Ello';
all_from 'lib/WebService/Ello.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
