namespace LibroSphere.Application.Exceptions
{
    public abstract class CustomException : Exception
    {
        protected CustomException(string message) : base(message)
        {
        }
    }

    public class BusinessException : CustomException
    {
        public BusinessException(string message) : base(message)
        {
        }
    }

    public class NotFoundException : CustomException
    {
        public NotFoundException(string message) : base(message)
        {
        }
    }
}
