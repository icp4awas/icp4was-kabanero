// 
// Decompiled by Procyon v0.5.36
// 

package app;

import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.GET;
import javax.ws.rs.core.Response;
import javax.ws.rs.Path;

@Path("/hello")
public class HelloWorldResource
{
    @GET
    public Response sayHello() {
        return Response.ok().entity((Object)"Hello World!").build();
    }
    
    @GET
    @Path("/server")
    @Produces({ "text/plain" })
    public Response getServer(@Context final HttpServletRequest req) {
        return Response.ok().entity((Object)(String.valueOf(req.getLocalName()) + ":" + req.getLocalPort())).build();
    }
}
