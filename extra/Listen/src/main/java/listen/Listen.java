// $Id: Listen.java,v 1.4 2006/12/12 18:23:00 vlahan Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


package listen;

import java.io.*;
import java.sql.SQLException;

import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

public class Listen {
    public static void main(String args[]) throws IOException {
        String source = null;
        PacketSource reader;
        if (args.length == 2 && args[0].equals("-comm")) {
          source = args[1];
        }
	else if (args.length > 0) {
	    System.err.println("usage: java net.tinyos.tools.Listen [-comm PACKETSOURCE]");
	    System.err.println("       (default packet source from MOTECOM environment variable)");
	    System.exit(2);
	}
        if (source == null) {	
  	  reader = BuildSource.makePacketSource();
        }
        else {
  	  reader = BuildSource.makePacketSource(source);
        }
	if (reader == null) {
	    System.err.println("Invalid packet source (check your MOTECOM environment variable)");
	    System.exit(2);
	}

	try {
	  reader.open(PrintStreamMessenger.err);
	  Database db = new Database();
	  for (;;) {
	    byte[] packet = reader.readPacket();
	    if(packet[4] >= 33 && packet[4] <= 36) {
		    Dump.printPacket(System.out, packet);
		    int node = packet[4];
		    int temp = (((packet[10]<<8)&0xFFFF) + (packet[11]&0xFF));
		    int light = (((packet[12]<<8)&0xFFFF) + (packet[13]&0xFF));
            boolean fire = packet[14]==1;
		    //System.out.println();
		    //System.out.flush();
		    System.out.println("\nnode: " + node);
		    System.out.println("temp: " + temp);
		    System.out.println("light: " + light);
		    System.out.println("fire: " + fire );
		    System.out.println("-------------------------------");
		    try {
				db.put(node, temp, light, fire);
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
	    }
	  }
	}
	catch (IOException e) {
	    System.err.println("Error on " + reader.getName() + ": " + e);
	}
    }
}

