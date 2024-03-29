conf_data = configuration_data()
conf_data.set('APP_ID', application_id)
conf_data.set('APP_NAME', application_name)
conf_data.set('VERSION', meson.project_version())

config_header = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

whalewatcher_files = files(
    join_paths('Application.vala'),
    join_paths('MainWindow.vala'),
    join_paths('Layouts', 'MainLayout.vala'),
    join_paths('Models', 'DockerContainer.vala'),
    join_paths('Models', 'DockerEngineErrorResponse.vala'),
    join_paths('Models', 'DockerImageDetails.vala'),
    join_paths('Models', 'DockerImageLayer.vala'),
    join_paths('Models', 'DockerImageSummary.vala'),
    join_paths('Models', 'DockerVersion.vala'),
    join_paths('Models', 'DockerVolume.vala'),
    join_paths('Models', 'DockerVolumes.vala'),
    join_paths('Models', 'DockerServerState.vala'),
    join_paths('Models', 'DockerSystemDataUsage.vala'),
    join_paths('Models', 'Events', 'ContainerEvent.vala'),
    join_paths('Models', 'Events', 'DockerEngineEvent.vala'),
    join_paths('Models', 'Events', 'ImageEvent.vala'),
    join_paths('Services', 'DockerSocketClient.vala'),
    join_paths('Services', 'DockerService.vala'),
    join_paths('Services', 'SocketRestClient.vala'),
    join_paths('Util', 'JsonUtils.vala'),
    join_paths('Widgets', 'HeaderBar.vala'),
    join_paths('Widgets', 'CellRendererBadge.vala'),
    join_paths('Widgets', 'ContainersSidebar.vala'),
    join_paths('Widgets', 'ContainersSidebarRow.vala'),
    join_paths('Widgets', 'ImagesSourceList.vala'),
    join_paths('Widgets', 'ImageListCategory.vala'),
    join_paths('Widgets', 'ImageListItem.vala'),
    join_paths('Widgets', 'ImageTagListItem.vala'),
    join_paths('Widgets', 'VolumesSourceList.vala'),
    join_paths('Widgets', 'VolumeListItem.vala'),
    join_paths('Widgets', 'Dialogs', 'AuthDialog.vala'),
    join_paths('Widgets', 'Dialogs', 'ErrorDialog.vala'),
    join_paths('Widgets', 'Dialogs', 'RemoveImagesWarningDialog.vala'),
    join_paths('Widgets', 'Sidebar', 'ImagesEntry.vala'),
    join_paths('Widgets', 'Sidebar', 'ContainersEntry.vala'),
    join_paths('Widgets', 'Sidebar', 'NetworksEntry.vala'),
    join_paths('Widgets', 'Sidebar', 'VolumesEntry.vala'),
    join_paths('Widgets', 'Sidebar', 'SidebarWidget.vala'),
    join_paths('Widgets', 'Sidebar', 'SidebarEntry.vala'),
    join_paths('Views', 'ErrorView.vala'),
    join_paths('Views', 'LoadingView.vala'),
    join_paths('Views', 'ImagesView.vala'),
    join_paths('Views', 'ImageTagView.vala'),
    join_paths('Views', 'Images', 'BrowseImagesView.vala'),
    join_paths('Views', 'Images', 'InspectImageView.vala'),
    join_paths('Views', 'ContainersView.vala'),
    join_paths('Views', 'ContainerPage.vala'),
    join_paths('Views', 'VolumesView.vala'),
    join_paths('Views', 'VolumeView.vala'),
    join_paths('Views', 'NetworksView.vala'),
    join_paths('Views', 'WelcomeView.vala')
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    application_id,
    whalewatcher_files,
    config_header,
    # css_gresource,
    dependencies: [
        dependency('gtk+-3.0', version: '>= 3.6.4'),
        dependency('gee-0.8', version: '>= 0.8.5'),
        dependency('glib-2.0', version: '>= 2.30.0'),
        dependency('granite', version: '>= 0.6.0'),
        dependency('gtksourceview-4'),
        dependency('libsoup-2.4'),
        dependency('json-glib-1.0'),
        dependency('libhandy-1', version: '>=1.0.0')
    ],
    vala_args: vala_args,
    install: true
)
