<?php

/*
Plugin Name: Polyscripting for WordPress
Plugin URI: http://URI_Of_Page_Describing_Plugin_and_Updates
Description: A brief description of the Plugin.
Version: 1.0
Author: bluegaston
Author URI: http://URI_Of_The_Plugin_Author
License: A "Slug" license name e.g. GPL2
*/

function get_polyscript_status() {
    return getenv('MODE') == 'polyscripted';
}

function set_polyscript_status()
{
    $lang = '';
    if ('en_' !== substr(get_user_locale(), 0, 3)) {
        $lang = ' lang="en"';
    }

    printf(
        '<p id="dolly"><span class="screen-reader-text">%s </span><span dir="ltr"%s>%s</span></p>',
        __('Polyscripint Status:'),
        $lang,
        get_polyscript_status() ? "Polyscripting Enabled" : "Polyscripting Disabled");
}

// Now we set that function up to execute when the admin_notices action is called.
add_action( 'admin_notices', 'set_polyscript_status' );

// We need some CSS to position the paragraph.
function poly_css() {
    echo "
	<style type='text/css'>
	#dolly {
		float: right;
		padding: 5px 10px;
		margin: 0;
		font-size: 12px;
		line-height: 1.6666;
	}
	.rtl #dolly {
		float: left;
	}
	.block-editor-page #dolly {
		display: none;
	}
	@media screen and (max-width: 782px) {
		#dolly,
		.rtl #dolly {
			float: none;
			padding-left: 0;
			padding-right: 0;
		}
	}
	</style>
	";
}

add_action( 'admin_head', 'poly_css' );
