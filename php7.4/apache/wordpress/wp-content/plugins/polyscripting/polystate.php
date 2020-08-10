<?php

class Polystate
{
    private static $initiated = false;
    private static $state = 'unknown';
    private static $host;
    private static $port;

    public static function init() {
        if (!self::$initiated) {
            self::init_polystate();
        }
    }

    private static function init_polystate()
    {
        self::$initiated = true;
        self::$state = self::get_live_state();
        self::$host = $_SERVER['SERVER_ADDR'];
        self::$port = 2323;
    }

    static function get_saved_state() {
        return get_option('polyscript_state');
    }

    static function get_live_state() {
        if (self::is_polyscripted()) {
            return true;
        } else {
            return false;
        }
    }

    static function sanitize_state() {
        $cur_state = self::get_saved_state();
        if ($cur_state == 'on' && !self::is_polyscripted()) {
            self::signal_state_shift('scrambling');
        } else if ($cur_state == 'off' && self::is_polyscripted()) {
            self::signal_state_shift('disabling');
        } else if ($cur_state == 'scrambling' && self::is_polyscripted()) {
            self::update_saved_state('on');
        } else if ($cur_state == 'disabling' && !self::is_polyscripted()) {
            self::update_saved_state('off');
        } else if ($cur_state == 'rescrambling' && self::is_polyscripted()) {
            self::check_rescramble_shift();
        } else if ($cur_state == 'scrambling' || $cur_state == 'disabling') {
            self::check_shift_timeout();
        }
    }

    private static function check_shift_timeout() {
        if ((time() - get_option('polyscript_shift_timestamp', time())) > 300) {
            update_option('polyscript_warning', 'timeout');
            self::update_saved_state(self::get_live_state() ? 'on' : 'off');
        }
    }

    public static function check_warning(){
        return get_option('polyscript_warning') == 'timeout' || get_option('polyscript_warning') == 'socket_fail';
    }

    public static function clear_warning(){
        return delete_option('polyscript_warning');
    }

    public static function shift_state($state)
    {
        switch ($state) {
            case 'scrambling':
                self::signal_state_shift('scrambling');
                break;
            case 'rescrambling':
                self::signal_state_shift('rescrambling');
                break;
            case 'disabling':
                self::signal_state_shift('disabling');
                break;
            default:
                die ("Unknown Error Reached");
        }
    }

    private static function check_rescramble_shift() {
        if (get_option('polyscript_dummy') != hash_file('md5', plugin_dir_path(__FILE__) . 'dummy.php')) {
            delete_option('polyscript_dummy');
            self::update_saved_state('on');
        } else {
            self::check_shift_timeout();
        }
    }

    private static function update_saved_state($new_state) {
        update_option('polyscript_state', $new_state);
    }

    private static function is_polyscripted() {
        try {
            $result = eval("if (true) { echo ''; return 1; }");
        } catch (ParseError $result) {
            return true;
        }
        return false;
    }

    private static function signal_state_shift($new_state) {
        switch($new_state) {
            case 'scrambling':
                $signal="1 ";
                break;
            case 'rescrambling':
                $signal="2 ";
                update_option('polyscript_dummy', hash_file('md5', plugin_dir_path(__FILE__) . 'dummy.php'));
                break;
            case 'disabling':
                $signal="3 ";
                break;
            default:
                return 0;
        }

        if ( self::send_scramble_signal($signal) ) {
            self::update_saved_state($new_state);
            update_option('polyscript_shift_timestamp', time());
            return 1;
        } else {
            update_option('polyscript_warning', 'socket_fail');
            die ("Could not communicate with socket. State shift unavailable.");
        }

    }

    private static function send_scramble_signal($signal) {
        $socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
        if (!$socket) {
            return false;
        }
        $stream = stream_socket_client("tcp://" . self::$host . ":" . self::$port);
        if (!$stream) {
            return false;
        }

        if (!fwrite($stream, $signal))  {
            return false;
        }

        fclose($stream);
        return true;
    }
}