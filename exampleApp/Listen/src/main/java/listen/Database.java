package listen;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;
import java.sql.Connection;
import java.sql.PreparedStatement;

public class Database {

	private final String userName = "adam";
	private final String password = "password";
	private final String dbmsAddress = "jdbc:mysql://176.58.117.67:3306/pervasive";
	
	private Connection connection;
	
	public Database(){
		try {
			connection = getConnection();
		} catch (SQLException e) {
			System.err.println("Can't connect to database");
			e.printStackTrace();
			System.exit(1);
		}
	}

	public void put(int node, int heat, int light, boolean fire) throws SQLException {
		String query = "INSERT INTO data (node_id, heat, light, fire) VALUES( ?, ?, ?, ? )";
		PreparedStatement stmt = connection.prepareStatement(query);
		stmt.setInt(1,node);
		stmt.setInt(2,heat);
		stmt.setInt(3,light);
		stmt.setBoolean(4, fire);
		stmt.executeUpdate();
	}

	public Connection getConnection() throws SQLException {

		try {
			Class.forName("com.mysql.jdbc.Driver");
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		}

		Connection conn = null;
		Properties connectionProps = new Properties();
		connectionProps.put("user", this.userName);
		connectionProps.put("password", this.password);
		conn = DriverManager.getConnection(
				dbmsAddress,
				connectionProps);
		return conn;
	}

}
