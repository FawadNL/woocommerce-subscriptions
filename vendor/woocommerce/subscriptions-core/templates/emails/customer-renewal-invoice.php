<?php
/**
 * Customer renewal invoice email
 *
 * @package WooCommerce_Subscriptions/Templates/Emails
 * @version 7.3.0 - Updated for WC core email improvements.
 */
defined( 'ABSPATH' ) || exit;

$email_improvements_enabled = wcs_is_wc_feature_enabled( 'email_improvements' );

do_action( 'woocommerce_email_header', $email_heading, $email );

echo $email_improvements_enabled ? '<div class="email-introduction">' : '';

/* translators: %s: Customer first name */ ?>
<p><?php printf( esc_html__( 'Hi %s,', 'woocommerce-subscriptions' ), esc_html( $order->get_billing_first_name() ) ); ?></p>

<?php if ( $order->has_status( 'pending' ) ) : ?>
	<p>
		<?php
		echo wp_kses(
			sprintf(
				// translators: %1$s: name of the blog, %2$s: link to checkout payment url, note: no full stop due to url at the end.
				_x(
					'An order has been created for you to renew your subscription on %1$s. To pay for this invoice please use the following link: %2$s',
					'In customer renewal invoice email',
					'woocommerce-subscriptions'
				),
				esc_html( get_bloginfo( 'name' ) ),
				'<a href="' . esc_url( $order->get_checkout_payment_url() ) . '">'
				. esc_html__( 'Pay Now &raquo;', 'woocommerce-subscriptions' ) .
				'</a>'
			),
			[
				'a' => [ 'href' => true ],
			]
		);
		?>
	</p>
<?php elseif ( $order->has_status( 'failed' ) ) : ?>
	<p>
		<?php
		echo wp_kses(
			sprintf(
				// translators: %1$s: name of the blog, %2$s: link to checkout payment url, note: no full stop due to url at the end.
				_x(
					'The automatic payment to renew your subscription with %1$s has failed. To reactivate the subscription, please log in and pay for the renewal from your account page: %2$s',
					'In customer renewal invoice email',
					'woocommerce-subscriptions'
				),
				esc_html( get_bloginfo( 'name' ) ),
				'<a href="' . esc_url( $order->get_checkout_payment_url() ) . '">'
				. esc_html__( 'Pay Now &raquo;', 'woocommerce-subscriptions' ) .
				'</a>'
			),
			[
				'a' => [ 'href' => true ],
			]
		);
		?>
	</p>
<?php endif; ?>

<?php echo $email_improvements_enabled ? '</div>' : ''; ?>

<?php
do_action( 'woocommerce_subscriptions_email_order_details', $order, $sent_to_admin, $plain_text, $email );

/**
 * Show user-defined additional content - this is set in each email's settings.
 */
if ( $additional_content ) {
	echo $email_improvements_enabled ? '<div class="email-additional-content">' : '';
	echo wp_kses_post( wpautop( wptexturize( $additional_content ) ) );
	echo $email_improvements_enabled ? '</div>' : '';
}

do_action( 'woocommerce_email_footer', $email );
