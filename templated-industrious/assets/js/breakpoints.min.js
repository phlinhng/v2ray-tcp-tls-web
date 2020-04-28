/* breakpoints.js v0.1-dev | @ajlkn | MIT licensed */

var breakpoints = (function() { "use strict"; var _ = {

	/**
	 * List.
	 * @var {array}
	 */
	list: null,

	/**
	 * Media cache.
	 * @var {object}
	 */
	media: {},

	/**
	 * Events.
	 * @var {array}
	 */
	events: [],

	/**
	 * Initialize.
	 * @param {array} list List.
	 */
	init: function(list) {

		// Set list.
			_.list = list;

		// Add event listeners.
			window.addEventListener('resize',				_.poll);
			window.addEventListener('orientationchange',	_.poll);
			window.addEventListener('load',					_.poll);
			window.addEventListener('fullscreenchange',		_.poll);

	},

	/**
	 * Determines if a given query is active.
	 * @param {string} query Query.
	 * @return {bool} True if yes, false if no.
	 */
	active: function(query) {

		var breakpoint, op, media,
			a, x, y, units;

		// Media for this query doesn't exist? Generate it.
			if (!(query in _.media)) {

				// Determine operator, breakpoint.

					// Greater than or equal.
						if (query.substr(0, 2) == '>=') {

							op = 'gte';
							breakpoint = query.substr(2);

						}

					// Less than or equal.
						else if (query.substr(0, 2) == '<=') {

							op = 'lte';
							breakpoint = query.substr(2);

						}

					// Greater than.
						else if (query.substr(0, 1) == '>') {

							op = 'gt';
							breakpoint = query.substr(1);

						}

					// Less than.
						else if (query.substr(0, 1) == '<') {

							op = 'lt';
							breakpoint = query.substr(1);

						}

					// Not.
						else if (query.substr(0, 1) == '!') {

							op = 'not';
							breakpoint = query.substr(1);

						}

					// Equal.
						else {

							op = 'eq';
							breakpoint = query;

						}

				// Build media.
					if (breakpoint && breakpoint in _.list) {

						a = _.list[breakpoint];

						// Range.
							if (Array.isArray(a)) {

								x = parseInt(a[0]);
								y = parseInt(a[1]);

								if (!isNaN(x))
									units = a[0].substr(String(x).length);
								else if (!isNaN(y))
									units = a[1].substr(String(y).length);
								else
									return;

								// Max only.
									if (isNaN(x)) {

										switch (op) {

											// Greater than or equal (>= 0 / anything)
												case 'gte':
													media = 'screen';
													break;

											// Less than or equal (<= y)
												case 'lte':
													media = 'screen and (max-width: ' + y + units + ')';
													break;

											// Greater than (> y)
												case 'gt':
													media = 'screen and (min-width: ' + (y + 1) + units + ')';
													break;

											// Less than (< 0 / invalid)
												case 'lt':
													media = 'screen and (max-width: -1px)';
													break;

											// Not (> y)
												case 'not':
													media = 'screen and (min-width: ' + (y + 1) + units + ')';
													break;

											// Equal (<= y)
												default:
													media = 'screen and (max-width: ' + y + units + ')';
													break;

										}

									}

								// Min only.
									else if (isNaN(y)) {

										switch (op) {

											// Greater than or equal (>= x)
												case 'gte':
													media = 'screen and (min-width: ' + x + units + ')';
													break;

											// Less than or equal (<= inf / anything)
												case 'lte':
													media = 'screen';
													break;

											// Greater than (> inf / invalid)
												case 'gt':
													media = 'screen and (max-width: -1px)';
													break;

											// Less than (< x)
												case 'lt':
													media = 'screen and (max-width: ' + (x - 1) + units + ')';
													break;

											// Not (< x)
												case 'not':
													media = 'screen and (max-width: ' + (x - 1) + units + ')';
													break;

											// Equal (>= x)
												default:
													media = 'screen and (min-width: ' + x + units + ')';
													break;

										}

									}

								// Min and max.
									else {

										switch (op) {

											// Greater than or equal.
												case 'gte':
													media = 'screen and (min-width: ' + x + units + ')';
													break;

											// Less than or equal.
												case 'lte':
													media = 'screen and (max-width: ' + y + units + ')';
													break;

											// Greater than.
												case 'gt':
													media = 'screen and (min-width: ' + (y + 1) + units + ')';
													break;

											// Less than.
												case 'lt':
													media = 'screen and (max-width: ' + (x - 1) + units + ')';
													break;

											// Not.
												case 'not':
													media = 'screen and (max-width: ' + (x - 1) + units + '), screen and (min-width: ' + (y + 1) + units + ')';
													break;

											// Equal.
												default:
													media = 'screen and (min-width: ' + x + units + ') and (max-width: ' + y + units + ')';
													break;

										}

									}

							}

						// String.
							else {

								// Missing a media type? Prefix with "screen".
									if (a.charAt(0) == '(')
										media = 'screen and ' + a;

								// Otherwise, use as-is.
									else
										media = a;

							}

					}

				// Cache.
					_.media[query] = (media ? media : false);

			}

		return (
			_.media[query] === false
			? false
			: window.matchMedia(_.media[query]).matches
		);

	},

	/**
	 * Registers an event.
	 * @param {string} query Query.
	 * @param {function} handler Handler.
	 */
	on: function(query, handler) {

		// Register event.
			_.events.push({
				query: query,
				handler: handler,
				state: false
			});

		// Query active *right now*? Call handler.
			if (_.active(query))
				(handler)();

	},

	/**
	 * Polls for events.
	 */
	poll: function() {

		var i, e;

		// Step through events.
			for (i=0; i < _.events.length; i++) {

				// Get event.
					e = _.events[i];

				// Active?
					if (_.active(e.query)) {

						// Hasn't been called yet?
							if (!e.state) {

								// Mark as called.
									e.state = true;

								// Call handler.
									(e.handler)();

							}

					}

				// Otherwise ...
					else {

						// Previously called?
							if (e.state) {

								// Unmark as called.
									e.state = false;

							}

					}

			}

	},

}; function __(list) { _.init(list); }; __._ = _; __.on = function(query, handler) { _.on(query, handler); }; __.active = function(query) { return _.active(query); }; return __; })();

// UMD Wrapper (github.com/umdjs/umd/blob/master/returnExports.js | @umdjs + @nason)
(function(root, factory) {

	// AMD.
		if (typeof define === 'function' && define.amd)
			define([], factory);

	// Node.
		else if (typeof exports === 'object')
			module.exports = factory();

	// Breakpoints global.
		else
			root.breakpoints = factory();

}(this, function() { return breakpoints; }));