<?php
/*
Copyright (c) 2020 Polyverse Corporation
*/

function is_polyscripted() {
    return polyscript_check();
}

function dependencies_check() {
    return file_exists("/usr/local/bin/polyscripting/build-scrambled.sh");
}

function is_rescrambling() {
    return get_state() == "scrambling";
}

function update_polyscript_state($state) {
    switch($state) {
        case "disabling":
            if (!polyscript_check()) {
                update_option('polyscript_state', $state);
            } else {
                update_option('polysript_state', 'off');
            }
            break;
        case "scrambling":
            if (polyscript_check()) {
                update_option('polyscript_state', 'on');
            } else {
                update_option('polyscript_state', $state);
            }
            break;
        case "on":
            if (polyscript_check()) {
                update_option('polyscript_state', $state);
            } else {
                return 0;
            }
            break;
        case "off":
            if (!polyscript_check()){
                update_option('polyscript_state', $state);
            } else {
                return 0;
            }
            break;
        default:
            return 0;
    }
    return 1;
}

function get_state() {
    return get_option('polyscript_state');
}

function refresh_polyscript_state() {
    $cur_state = get_state();
    if ($cur_state == 'disabled' && !is_polyscripted()) {
        update_polyscript_state('off');
    } else if ($cur_state == 'scrambling' && is_polyscripted()) {
        update_polyscript_state('on');
    }
}

function polyscript_check() {
    try {
        $result = eval("if (true) { echo ''; return 1; }");
    } catch (ParseError $result) {
        return true;
    }
    return false;
}

function check_state() {
    $state = get_state();
    switch ($state) {
        case 'on':
            return is_polyscripted();
            break;
        case 'off':
            return !is_polyscripted();
        case 'disabling':
            return update_polyscript_state('disabling');
        case 'scrambling':
            return update_polyscript_state('scrambling');
            break;
        default:
            update_polyscript_state(is_polyscripted() ? 'on' : 'off');
    }
}

function polyscript_rescramble() {
    $host = "172.17.0.3";
    $port = 2323;
    // No Timeout
    set_time_limit(0);
    $socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP) or die("Could not create socket\n");
    $stream = stream_socket_client("tcp://$host:$port");
    //$socket = socket_import_stream($stream);
    //socket_set_option($socket, SOL_SOCKET, SO_KEEPALIVE, 1);

    print("hello");
    print($host . ":" . $port);

    fwrite($stream, "1 ");

    stream_socket_shutdown($stream, STREAM_SHUT_WR); /* This is the important line */

    $contents = stream_get_contents($stream);

    fclose($stream);

    echo $contents;
    echo "done";

//    $result = socket_connect($socket, $host, $port) or die("Could not connect to socket\n");
//    $res = socket_write ( $socket , chr(1)) or die ("could not write");
//    socket_send($socket, "1\0", strlen("2"), MSG_EOR) or die ("Could not send");

    //socket_shutdown($socket);
    //update_polyscript_state("scrambling");

}

function polyscript_disable() {
    update_polyscript_state("disabling");
}