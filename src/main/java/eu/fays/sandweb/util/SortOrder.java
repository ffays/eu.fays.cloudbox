package eu.fays.sandweb.util;

/**
 * Sort order
 * @author Frederic Fays
 */
public enum SortOrder {
	/** Sort ascending */
	ASC(1),
	/** Sort descending */
	DESC(-1);

	private SortOrder(final int sign) {
		this.sign = sign;
	}

	public final int sign;
}
