<div class="widget">
    <?php if ( Polyscript::dependencies_check() ) {
        Polyscript::view('buttons', array('state' => $state));
        ?>
        <?php
    } else {?>
        <div class="centered polyscript-box-header">
            <h2><?php esc_html_e( 'No Polyscripting Dependencies Found.', 'polyscript' ); ?></h2>
            <h4><?php esc_html_e( 'Click the link below to learn how to enable polyscipting on your WordPress Site.', 'polyscript' ); ?></h4>
            <a href="http://www.polyverse.com/products/polyscripting">Polyscipting Dependencies</a>
        </div>
    <?php
    } ?>
</div>
<a class="inline"" href="options-general.php?page=polyscript">settings</a>

