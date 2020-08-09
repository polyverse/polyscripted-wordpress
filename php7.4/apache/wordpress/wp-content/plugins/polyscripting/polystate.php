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
            self::signal_state_shift('on');
        } else if ($cur_state == 'off' && self::is_polyscripted()) {
            self::signal_state_shift('off');
        } else if ($cur_state == 'scrambling' && self::is_polyscripted()) {
            self::update_saved_state('on');
        } else if ($cur_state == 'disabling' && !self::is_polyscripted()) {
            self::update_saved_state('off');
        } else if ($cur_state == 'rescrambling' && self::is_polyscripted()) {
            self::check_rescramble_shift();
        } else if ($cur_state == 'scrambling' || $cur_state == 'rescrambling') {
            self::check_shift_timeout();
        }
    }

    private static function check_shift_timeout() {
        if ((time() - get_option('polyscript_shift_timestamp', time())) > 100) {
            //TODO: Add warning.
            self::update_saved_state(self::get_live_state() ? 'on' : 'off');
        }
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
                return 0;
        }
    }

    private static function check_rescramble_shift() {
        $socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
        if (!$socket) {
            return false;
        }
        $stream = stream_socket_client("tcp://" . self::$host . ":" . self::$port);
        if (!$stream) {
            return false;
        }

        if ($contents = !fread($stream, 1024))  {
            return false;
        }

        die($contents);

        fclose($stream);
        return true;
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
            die (self::$host);
            //TODO add warning notification/failure.
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