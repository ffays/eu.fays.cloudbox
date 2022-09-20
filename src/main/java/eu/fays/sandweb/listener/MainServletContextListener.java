package eu.fays.sandweb.listener;

import java.text.MessageFormat;
import java.util.logging.Level;
import java.util.logging.Logger;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

/**
 * Main Servlet Context listener
 * @author Frederic Fays
 */
@WebListener
public class MainServletContextListener implements ServletContextListener {

	// //////////////////////////////////////////////////////////
	// Initialization
	// //////////////////////////////////////////////////////////

	/**
	 * @see jakarta.servlet.ServletContextListener#contextInitialized(jakarta.servlet.ServletContextEvent)
	 */
	@Override
	public void contextInitialized(final ServletContextEvent event) {
		LOGGER.log(Level.INFO, MessageFormat.format("Operating System {0} {1}", System.getProperty("os.name"), System.getProperty("os.arch")));
		LOGGER.log(Level.INFO, MessageFormat.format("Runtime {0} {1}", System.getProperty("java.runtime.name"), System.getProperty("java.runtime.version")));
	}

	/**
	 * @see jakarta.servlet.ServletContextListener#contextDestroyed(jakarta.servlet.ServletContextEvent)
	 */
	@Override
	public void contextDestroyed(final ServletContextEvent event) {
	}

	// //////////////////////////////////////////////////////////
	// Implementation
	// //////////////////////////////////////////////////////////

	/** Standard logger */
	private static final Logger LOGGER = Logger.getLogger(MainServletContextListener.class.getName());

}
