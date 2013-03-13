package listen;

import java.util.List;
import java.sql.*;
import java.util.LinkedList;

public class RetrieveFromDb {

  public List<Result> getResults(int number) {
    Database db = new Database();
    Connection c = db.getConnection();
    PreparedStatement stmt = c.prepareStatement("SELECT * FROM data ORDER BY timestamp DESC GROUP BY node_id LIMIT ?");
    stmt.setInt(1,numer);
    ResultSet rs = stmt.executeQuery();
    List<Result> results = new LinkedList<Result>();
    while(rs.next()) {
      results.add(new Result(rs.getInt("node_id"), rs.getInt("temp"),
      rs.getInt("light"), rs.getBoolean("node_id")));
    }
    return rs;
  }

  public class Result {
    public int node;
    public int temp;
    public int light;
    public boolean fire;

    public Result(int node, int temp, int light, boolean fire) {
      this.node = node;
      this.temp = temp;
      this.light = light;
      this.fire = fire;
    }
  }
}
