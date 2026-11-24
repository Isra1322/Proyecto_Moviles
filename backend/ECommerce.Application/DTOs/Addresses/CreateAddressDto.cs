namespace ECommerce.Application.DTOs.Addresses;

using System.ComponentModel.DataAnnotations;

public class CreateAddressDto
{
    [Required(ErrorMessage = "El título o alias de la dirección es obligatorio (ej. Casa, Trabajo).")]
    [StringLength(50, MinimumLength = 2, ErrorMessage = "El título debe tener entre 2 y 50 caracteres.")]
    public string Title { get; set; } = string.Empty;

    [Required(ErrorMessage = "La calle principal y número/intersección son obligatorios.")]
    [StringLength(200, MinimumLength = 5, ErrorMessage = "La dirección de calle debe tener entre 5 y 200 caracteres.")]
    public string Street { get; set; } = string.Empty;

    [Required(ErrorMessage = "La ciudad es obligatoria.")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "La ciudad debe tener entre 2 y 100 caracteres.")]
    public string City { get; set; } = string.Empty;

    [StringLength(100, ErrorMessage = "La provincia/departamento no puede superar los 100 caracteres.")]
    public string StateOrProvince { get; set; } = string.Empty;

    [StringLength(20, ErrorMessage = "El código postal no puede superar los 20 caracteres.")]
    public string? PostalCode { get; set; }

    [StringLength(250, ErrorMessage = "La referencia no puede superar los 250 caracteres.")]
    public string? Reference { get; set; }

    [Required(ErrorMessage = "El teléfono de contacto es obligatorio.")]
    [StringLength(30, MinimumLength = 7, ErrorMessage = "El teléfono debe tener entre 7 y 30 dígitos.")]
    public string Phone { get; set; } = string.Empty;

    public bool IsDefault { get; set; } = false;
}
