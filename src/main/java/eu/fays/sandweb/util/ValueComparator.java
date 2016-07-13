package eu.fays.sandweb.util;

import java.util.Comparator;
import java.util.Map;

/**
 * Comparator to sort in reverse order a map based on its values<br>
 * <a href="http://stackoverflow.com/questions/109383/how-to-sort-a-mapkey-value-on-the-values-in-java">How to sort a Map&lt;Key, Value&gt; on the values in Java</a><br>
 * Note: this comparator imposes orderings that are inconsistent with equals.<br>
 * Note: This comparator will throw a {@link NullPointerException} if either a key or a value is null.
 * @author Frederic Fays
 */
public class ValueComparator<T, U extends Comparable<U>> implements Comparator<T> {

	// //////////////////////////////////////////////////////////
	// Initialization
	// //////////////////////////////////////////////////////////

	/**
	 * Constructor
	 * @param base the source map
	 * @param order the sort order
	 */
	public ValueComparator(final Map<T, U> base, final SortOrder order) {
		//
		assert base != null;
		assert order != null;
		//
		_base = base;
		_order = order;
	}

	/**
	 * Constructor
	 * @param base the source map
	 */
	public ValueComparator(final Map<T, U> base) {
		this(base, SortOrder.ASC);
	}

	// //////////////////////////////////////////////////////////
	// Comparison
	// //////////////////////////////////////////////////////////

	/**
	 * @see java.util.Comparator#compare(java.lang.Object, java.lang.Object)
	 */
	@Override
	public int compare(final T a, final T b) {
		return _base.get(a).equals(_base.get(b)) ? _order.sign : _order.sign * _base.get(a).compareTo(_base.get(b));
	}

	// //////////////////////////////////////////////////////////
	// Implementation
	// //////////////////////////////////////////////////////////

	/** The source map. */
	final private Map<T, U> _base;

	/** The sort order. */
	final private SortOrder _order;
}
