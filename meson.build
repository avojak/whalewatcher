# Project name and programming language
project('com.github.avojak.whalewatcher', 'vala', 'c', version: '1.0.0')

i18n = import('i18n')
gnome = import('gnome')

vala_args = ['--pkg', 'posix']

# Check for dev profile
if get_option('profile') == 'default'
    application_id = meson.project_name()
    application_name = 'WhaleWatcher'
else
    application_id = '@0@-dev'.format(meson.project_name())
    application_name = 'WhaleWatcher (Development)'
    vala_args += ['-D', 'IS_DEVEL']
endif

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('meson/post_install.py')
