use inc::Module::Install;

all_from 'lib/App/CableCog.pm';
readme_from;
manifest_skip;

requires 'Cog::App';

install_share;

WriteAll;
