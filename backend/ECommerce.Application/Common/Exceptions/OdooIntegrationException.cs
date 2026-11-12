namespace ECommerce.Application.Common.Exceptions;

public class OdooIntegrationException : Exception
{
    public OdooIntegrationException(string message) : base(message)
    {
    }

    //Esta excepcion se lanzara cuando haya un error al integrar con Odoo 
    //si no responde o esta caido el servidor de Odoo
    
    public OdooIntegrationException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

