INSERT INTO cfg_nagios_broker_module (`cfg_nagios_id`, `broker_module`) VALUES (1, '@NDOMOD_BINARY@ config_file=@MONITORINGENGINE_ETC@/ndomod.cfg');

INSERT INTO `cfg_ndo2db` (`id`, `description`, `ndo2db_user`, `ndo2db_group`, `local`, `ns_nagios_server`, `socket_type`, `socket_name`, `tcp_port`, `db_servertype`, `db_host`, `db_name`, `db_port`, `db_prefix`, `db_user`, `db_pass`, `max_timedevents_age`, `max_systemcommands_age`, `max_servicechecks_age`, `max_hostchecks_age`, `max_eventhandlers_age`, `activate`) VALUES(1, 'Principal', '@MONITORINGENGINE_USER@', '@MONITORINGENGINE_GROUP@', '0', 1, 'tcp', '/var/run/ndo.sock', 5668, 'mysql', '@DB_HOST@', '@UTILS_DB@', '@DB_PORT@', 'nagios_', '@DB_USER@', '@DB_PASS@', '1440', '1440', '1440', '1440', '1440', '1');

INSERT INTO `cfg_ndomod` (`id`, `description`, `local`, `ns_nagios_server`, `instance_name`, `output_type`, `output`, `tcp_port`, `output_buffer_items`, `buffer_file`, `file_rotation_interval`, `file_rotation_command`, `file_rotation_timeout`, `reconnect_interval`, `reconnect_warning_interval`, `data_processing_options`, `config_output_options`, `activate`) VALUES(1, 'Central-mod', NULL, 1, 'Central', 'tcpsocket', '127.0.0.1', '5668', 5000, NULL, 14400, NULL, 60, 15, 900, -1, 3, '1');

INSERT INTO `options` (`key`, `value`) VALUES ('broker', 'ndo');
INSERT INTO `options` (`key`, `value`) VALUES ('centstorage', '1');

INSERT INTO `options` (`key`, `value`) VALUES ('enable_perfdata_sync', '1');
INSERT INTO `options` (`key`, `value`) VALUES ('enable_logs_sync', '1');